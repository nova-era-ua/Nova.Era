/* Document */
------------------------------------------------
create or alter procedure doc.[Document.Stock.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(255),
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Operation bigint = -1,
@Agent bigint = null,
@Warehouse bigint = null,
@Company bigint = null,
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec doc.[Document.DeleteTemp] @TenantId = @TenantId, @UserId = @UserId;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date;
	set @end = dateadd(day, 1, @To);

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @docs table(rowno int identity(1, 1), id bigint, op bigint, agent bigint, 
		comp bigint, whfrom bigint, whto bigint, rowcnt int);

	insert into @docs(id, op, agent, comp, whfrom, whto, rowcnt)
	select d.Id, d.Operation, d.Agent, d.Company, d.WhFrom, d.WhTo,
		count(*) over()
	from doc.Documents d
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and d.Operation = ml.Operation
	where d.TenantId = @TenantId and d.Temp = 0 and ml.Menu = @Menu
		and (d.[Date] >= @From and d.[Date] < @end)
		and (@Operation = -1 or d.Operation = @Operation)
		and (@Agent is null or d.Agent = @Agent)
		and (@Company is null or d.Company = @Company)
		and (@Warehouse is null or d.WhFrom = @Warehouse or d.WhTo = @Warehouse)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'date' then d.[Date]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'sum' then d.[Sum]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'no' then isnull(d.[SNo], d.[No])
				when N'memo' then d.[Memo]
			end
		end asc,
		-- desc
		case when @Dir = N'desc' then
			case @Order
				when N'date' then d.[Date]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'sum' then d.[Sum]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order 
				when N'no' then isnull(d.[SNo], d.[No])
				when N'memo' then d.[Memo]
			end
		end desc,
		Id desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.SNo, d.[No],
		d.Notice, d.Done, d.BindKind, d.BindFactor,
		[Operation!TOperation!RefId] = d.Operation, 
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[WhFrom!TWarehouse!RefId] = d.WhFrom, [WhTo!TWarehouse!RefId] = d.WhTo,
		[!!RowCount] = t.rowcnt
	from @docs t inner join 
		doc.Documents d on d.TenantId = @TenantId and d.Id = t.id
	order by t.rowno;

	-- maps
	with T as (select op from @docs group by op)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o 
		inner join T t on o.TenantId = @TenantId and o.Id = op;

	with T as (select agent from @docs group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with W as (select wh = whfrom from @docs union all select wh = whto from @docs),
	T as (select wh from W group by wh)
	select [!TWarehouse!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Warehouses a 
		inner join T t on a.TenantId = @TenantId and a.Id = wh;

	with T as (select comp from @docs group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	-- menu
	select [Menu!TMenu!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], FormId = f.Id, FormName = f.[Name],
		o.[DocumentUrl]
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by f.[Order];

	select [Operations!TOperation!Array] = null, [Id!!Id] = -1, [Name!!Name] = N'@[Filter.AllOperations]', null, null, [!Order] = -1
	union all
	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form], o.DocumentUrl, [!Order] = o.Id
	from doc.Operations o
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by [!Order];

	-- filters
	select [!$System!] = null, [!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To,
		[!Documents.Operation!Filter] = @Operation, 
		[!Documents.Agent.Id!Filter] = @Agent, [!Documents.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent),
		[!Documents.Company.Id!Filter] = @Company, [!Documents.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!Documents.Warehouse.Id!Filter] = @Warehouse, [!Documents.Warehouse.Name!Filter] = cat.fn_GetWarehouseName(@TenantId, @Warehouse)
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Operation bigint = null,
@CheckRems bit = 0
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docform nvarchar(16);
	declare @done bit;
	if @Operation is null
		select @Operation = d.Operation from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id;

	if @Id <> 0 and 1 = (select Done from doc.Documents where TenantId =@TenantId and Id = @Id)
		set @CheckRems = 0;
	set @CheckRems = app.fn_IsCheckRems(@TenantId, @CheckRems);

	select @docform = o.Form from doc.Operations o where o.TenantId = @TenantId and o.Id = @Operation;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.SNo, d.[No], d.Notice, d.[Sum], d.Done, d.BindKind, d.BindFactor,
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, [WhFrom!TWarehouse!RefId] = d.WhFrom,
		[WhTo!TWarehouse!RefId] = d.WhTo, [Contract!TContract!RefId] = d.[Contract], 
		[PriceKind!TPriceKind!RefId] = d.PriceKind, [RespCenter!TRespCenter!RefId] = d.RespCenter,
		[CostItem!TCostItem!RefId] = d.CostItem, [ItemRole!TItemRole!RefId] = d.ItemRole, [Project!TProject!RefId] = d.Project,
		[StockRows!TRow!Array] = null,
		[ServiceRows!TRow!Array] = null,
		[ParentDoc!TDocBase!RefId] = d.Parent, [BaseDoc!TDocBase!RefId] = d.Base,
		[LinkedDocs!TDocBase!Array] = null,
		[Extra!TDocExtra!Object] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	declare @rows table(id bigint, item bigint, unit bigint, [role] bigint, costitem bigint);
	insert into @rows (id, item, unit, [role], costitem)
	select Id, Item, Unit, ItemRole, CostItem from doc.DocDetails dd
	where dd.TenantId = @TenantId and dd.Document = @Id;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], FQty, Price, [Sum], ESum, DSum, TSum,
		[Item!TItem!RefId] = dd.Item, [Unit!TUnit!RefId] = Unit, 
		[ItemRole!TItemRole!RefId] = dd.ItemRole, [ItemRoleTo!TItemRole!RefId] = dd.ItemRoleTo,
		[CostItem!TCostItem!RefId] = dd.CostItem,
		[!TDocument.StockRows!ParentId] = dd.Document, [RowNo!!RowNumber] = RowNo,
		Rem = r.[Rem]
	from doc.DocDetails dd
		left join doc.fn_getDocumentRems(@CheckRems, @TenantId, @Id) r on dd.Item = r.Item and dd.ItemRole = r.[Role]
	where dd.TenantId=@TenantId and dd.Document = @Id and dd.Kind = N'Stock'
	order by RowNo;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], FQty, Price, [Sum], ESum, DSum, TSum, 
		[Item!TItem!RefId] = Item, [Unit!TUnit!RefId] = Unit, [ItemRole!TItemRole!RefId] = dd.ItemRole,
		[CostItem!TCostItem!RefId] = dd.CostItem,
		[!TDocument.ServiceRows!ParentId] = dd.Document, [RowNo!!RowNumber] = RowNo
	from doc.DocDetails dd
	where dd.TenantId=@TenantId and dd.Document = @Id and dd.Kind = N'Service'
	order by RowNo;

	select [!TDocExtra!Object] = null, [Id!!Id] = da.Id, da.[WriteSupplierPrices], da.[IncludeServiceInCost],
		[!TDocument.Extra!ParentId] = da.Id
	from doc.DocumentExtra da where da.TenantId = @TenantId and da.Id = @Id;

	-- maps
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl,
		[Links!TOpLink!Array] = null
	from doc.Operations o 
	where o.TenantId = @TenantId and o.Id = @Operation;

	select [!TOpLink!Array] = null, [Id!!Id] = ol.Id, ol.Category, ch.[Name], [!TOperation.Links!ParentId] = ol.Parent
	from doc.OperationLinks ol 
		inner join doc.Operations ch on ol.TenantId = ch.TenantId and ol.Operation = ch.Id
	where ol.TenantId = @TenantId and ol.Parent = @Operation;

	select [!TWarehouse!Map] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name]
	from cat.Warehouses w inner join doc.Documents d on d.TenantId = w.TenantId and w.Id in (d.WhFrom, d.WhTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by w.Id, w.[Name];

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind,
		[CostItem!TCostItem!RefId] = ir.CostItem
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0;

	with T as (
		select CostItem from doc.Documents d where TenantId = @TenantId and d.Id = @Id
		union all 
		select costitem from @rows dd group by costitem
		union all
		select ir.CostItem from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0
		group by ir.CostItem
	)
	select [!TCostItem!Map] = null, [Id!!Id] = ci.Id, [Name!!Name] = ci.[Name]
	from cat.CostItems ci 
	where ci.TenantId = @TenantId and ci.Id in (select CostItem from T);

	with T as (select PriceKind from doc.Documents d where TenantId = @TenantId and d.Id = @Id
		union all 
		select c.PriceKind from doc.Documents d inner join doc.Contracts c on d.TenantId = @TenantId and d.[Contract] = c.Id
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk 
	where pk.TenantId = @TenantId and pk.Id in (select PriceKind from T);

	exec doc.[Document.MainMaps] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;
	exec doc.[Document.LinkedMaps]  @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

	with T as (select item from @rows group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], Article, Barcode,
		Price = cast(null as float), Rem = cast(null as float),
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit!] = u.Short, 
		[Role.Id!TItemRole!RefId] = i.[Role],
		[CostItem.Id!TCostItem!Id] = ir.[CostItem], [CostItem.Name!TCostItem!Name] = ci.[Name]
	from cat.Items i inner join T on i.Id = T.item and i.TenantId = @TenantId
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
		left join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
		left join cat.CostItems ci on i.TenantId = ci.TenantId and ir.CostItem = ci.Id
	where i.TenantId = @TenantId;

	with T as (select unit from @rows group by unit)
	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.Short
	from cat.Units u inner join T on u.Id = T.unit and u.TenantId = @TenantId
	where u.TenantId = @TenantId;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form]
	from doc.Operations o where TenantId = @TenantId and Form=@docform
	order by Id;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [Params!TParam!Object] = null, [Operation] = @Operation, CheckRems = @CheckRems;

	select [!$System!] = null, [!!ReadOnly] = d.Done
	from doc.Documents d where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
drop procedure if exists doc.[Document.Stock.UpdateBase];
drop procedure if exists doc.[Document.Stock.Metadata];
drop procedure if exists doc.[Document.Stock.Update];
drop procedure if exists doc.[Document.Order.Metadata];
drop procedure if exists doc.[Document.Order.Update];
drop procedure if exists doc.[Document.Rows.Merge];
drop type if exists cat.[Document.Stock.TableType];
drop type if exists cat.[Document.Stock.Row.TableType];
drop type if exists cat.[Document.Extra.TableType];
go
------------------------------------------------
create type cat.[Document.Stock.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Sum] money,
	[SNo] nvarchar(64),
	[No] nvarchar(64),
	Operation bigint,
	Agent bigint,
	Company bigint,
	WhFrom bigint,
	WhTo bigint,
	[Contract] bigint,
	PriceKind bigint,
	RespCenter bigint,
	Project bigint,
	CostItem bigint,
	ItemRole bigint,
	Memo nvarchar(255)
)
go
------------------------------------------------
create type cat.[Document.Stock.Row.TableType]
as table(
	Id bigint null,
	ParentId bigint,
	RowNo int,
	Item bigint,
	Unit bigint,
	ItemRole bigint,
	ItemRoleTo bigint,
	[Qty] float,
	[FQty] float,
	[Price] money,
	[Sum] money,
	ESum money,
	DSum money,
	TSum money,
	Memo nvarchar(255),
	CostItem bigint
)
go
------------------------------------------------
create type cat.[Document.Extra.TableType]
as table(
	ParentId bigint,
	WriteSupplierPrices bit,
	IncludeServiceInCost bit
)
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Document cat.[Document.Stock.TableType];
	declare @Rows cat.[Document.Stock.Row.TableType]
	declare @Extra cat.[Document.Extra.TableType];

	select [Document!Document!Metadata] = null, * from @Document;
	select [Extra!Document.Extra!Metadata] = null, * from @Extra;
	select [StockRows!Document.StockRows!Metadata] = null, * from @Rows;
	select [ServiceRows!Document.ServiceRows!Metadata] = null, * from @Rows;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Rows.Merge]
@TenantId int = 1,
@Id bigint,
@Kind nvarchar(16),
@Rows cat.[Document.Stock.Row.TableType] readonly
as
begin
	with DD as (select * from doc.DocDetails where TenantId = @TenantId and Document = @Id and Kind=@Kind)
	merge DD as t
	using @Rows as s on t.Id = s.Id
	when matched then update set
		t.RowNo = s.RowNo,
		t.Item = s.Item,
		t.Unit = s.Unit,
		t.ItemRole = nullif(s.ItemRole, 0),
		t.ItemRoleTo = nullif(s.ItemRoleTo, 0),
		t.Qty = s.Qty,
		t.FQty = s.FQty,
		t.Price = s.Price,
		t.[Sum] = s.[Sum],
		t.ESum = s.ESum,
		t.DSum = s.DSum,
		t.TSum = s.TSum,
		t.CostItem = s.CostItem
	when not matched by target then insert
		(TenantId, Document, Kind, RowNo, Item, Unit, ItemRole, ItemRoleTo, Qty, FQty, Price, [Sum], ESum, DSum, TSum, 
			CostItem) values
		(@TenantId, @Id, @Kind, s.RowNo, s.Item, s.Unit, nullif(s.ItemRole, 0), nullif(s.ItemRoleTo, 0), s.Qty, s.FQty, s.Price, s.[Sum], s.ESum, s.DSum, s.TSum, 
			s.CostItem)
	when not matched by source and t.TenantId = @TenantId and t.Document = @Id and t.Kind=@Kind then delete;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.UpdateBase]
@TenantId int = 1,
@UserId bigint,
@Document cat.[Document.Stock.TableType] readonly,
@Extra cat.[Document.Extra.TableType] readonly,
@StockRows cat.[Document.Stock.Row.TableType] readonly,
@ServiceRows cat.[Document.Stock.Row.TableType] readonly,
@RetId bigint output
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Apply for xml auto);
	throw 60000, @xml, 0;
	*/

	declare @rtable table(id bigint);
	declare @id bigint;

	declare @no nvarchar(64);
	select @no = [No] from @Document;
	if @no is null
	begin
		declare @autonumAN bigint, @autonumComp bigint, @autonumDate date;

		select @autonumAN = o.Autonum, @autonumComp = d.Company, @autonumDate = d.[Date]
		from @Document d inner join doc.Operations o on d.Operation = o.Id and o.TenantId = @TenantId;

		exec doc.[Autonum.NextValue] 
			@TenantId = @TenantId, @Company = @autonumComp, @Autonum = @autonumAN, @Date = @autonumDate, @Number = @no output;
	end

	merge doc.Documents as t
	using @Document as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.Temp = 0,
		t.Operation = s.Operation,
		t.[Date] = s.[Date],
		t.[Sum] = s.[Sum],
		t.Company = s.Company,
		t.Agent = s.Agent,
		t.WhFrom = s.WhFrom,
		t.WhTo = s.WhTo,
		t.[Contract] = s.[Contract],
		t.PriceKind = s.PriceKind,
		t.RespCenter = s.RespCenter,
		t.Project = s.Project,
		t.CostItem = s.CostItem,
		t.ItemRole = s.ItemRole,
		t.Memo = s.Memo,
		t.SNo = s.SNo,
		t.[No] = @no
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, WhFrom, WhTo, [Contract], 
			PriceKind, RespCenter, Project, CostItem, ItemRole, Memo, SNo, [No], UserCreated) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, WhFrom, s.WhTo, s.[Contract], 
			s.PriceKind, s.RespCenter, s.Project, s.CostItem, s.ItemRole, s.Memo, s.SNo, @no, @UserId)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	merge doc.DocumentExtra as t
	using @Extra as s
	on t.TenantId = @TenantId and t.Id = @id
	when matched then update set
		t.WriteSupplierPrices = s.WriteSupplierPrices,
		t.IncludeServiceInCost = s.IncludeServiceInCost
	when not matched then insert
		(TenantId, Id, WriteSupplierPrices, IncludeServiceInCost) values
		(@TenantId, @id, s.WriteSupplierPrices, s.IncludeServiceInCost);

	exec doc.[Document.Rows.Merge] @TenantId = @TenantId, @Id = @id, @Kind = N'Stock', @Rows = @StockRows;
	exec doc.[Document.Rows.Merge] @TenantId = @TenantId, @Id = @id, @Kind = N'Service', @Rows = @ServiceRows;

	set @RetId = @id;
end
go

------------------------------------------------
create or alter procedure doc.[Document.Stock.Update]
@TenantId int = 1,
@UserId bigint,
@Document cat.[Document.Stock.TableType] readonly,
@Extra cat.[Document.Extra.TableType] readonly,
@StockRows cat.[Document.Stock.Row.TableType] readonly,
@ServiceRows cat.[Document.Stock.Row.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	declare @id bigint;
	exec doc.[Document.Stock.UpdateBase] @TenantId = @TenantId, @UserId = @UserId,
		@Document = @Document, @Extra = @Extra,
		@StockRows = @StockRows, @ServiceRows = @ServiceRows, @RetId = @id output;
	exec doc.[Document.Stock.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go