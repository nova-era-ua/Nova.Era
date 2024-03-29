﻿/* Document.Order */
------------------------------------------------
create or alter procedure doc.[Document.Order.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(255),
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'desc',
@Operation bigint = -1,
@Agent bigint = null,
@Company bigint = null,
@From date = null,
@To date = null,
@State nvarchar(1) = N'W'
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
		left join doc.DocStates ds on d.TenantId = ds.TenantId and d.[State] = ds.Id
	where d.TenantId = @TenantId and d.Temp = 0 and ml.Menu = @Menu
		and (d.[Date] >= @From and d.[Date] < @end)
		and (@Operation = -1 or d.Operation = @Operation)
		and (@Agent is null or d.Agent = @Agent)
		and (@Company is null or d.Company = @Company)
		and (@State = N'A' or @State = N'W' and ds.Kind in (N'I', N'P') or @State = ds.Kind)
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
		[State.Id!TState!Id] = d.[State], [State.Name!TState!Name] = ds.[Name], [State.Color!TState!] = ds.Color,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[WhFrom!TWarehouse!RefId] = d.WhFrom, [WhTo!TWarehouse!RefId] = d.WhTo,
		[LinkedDocs!TDocBase!Array] = null,
		[!!RowCount] = t.rowcnt
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and d.Id = t.id
		left join doc.DocStates ds on d.TenantId = ds.TenantId and d.[State] = ds.Id
	order by t.rowno;

	-- arrays
	-- from BASE!!!
	select [!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done], d.BindKind, d.BindFactor,
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Base
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and t.id = d.Base
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Base = t.id;

	/*
	-- payments/shipment
	select [!TBind!Object] = null, [!TDocument.Bind!ParentId] = [Base], [Payment], [Shipment] 
	from (
		select [Base], Kind = r.BindKind, [Sum] = [Sum] * r.BindFactor
		from doc.Documents r 
		inner join @docs t on r.TenantId = @TenantId and r.Base = t.id
	) 
	as s pivot (  
		sum([Sum])  
		for Kind in ([Payment], [Shipment])  
	) as p;  
	*/

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

	-- filters
	select [Operations!TOperation!Array] = null, [Id!!Id] = -1, [Name!!Name] = N'@[Filter.AllOperations]', null, null, [!Order] = -1
	union all
	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form], o.DocumentUrl, [!Order] = o.Id
	from doc.Operations o
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by [!Order];

	select [!$System!] = null, [!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To,
		[!Documents.Operation!Filter] = @Operation, 
		[!Documents.Agent.Id!Filter] = @Agent, [!Documents.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent),
		[!Documents.Company.Id!Filter] = @Company, [!Documents.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!Documents.State!Filter] = @State
end
go
------------------------------------------------
create or alter procedure doc.[Document.Order.Load]
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
		[State!TState!RefId] = d.[State], 
		[StockRows!TRow!Array] = null,
		[ServiceRows!TRow!Array] = null,
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

	-- from BASE!!!
	select [!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done], d.BindKind, d.BindFactor,
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Base
	from doc.Documents d 
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Base = @Id;

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

	select [States!TState!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color, Kind
	from doc.DocStates 
	where TenantId = @TenantId and Form = @docform
	order by [Order];

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [Params!TParam!Object] = null, [Operation] = @Operation, CheckRems = @CheckRems;

	select [!$System!] = null, [!!ReadOnly] = d.Done
	from doc.Documents d where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Order.Metadata]
as
begin
	set nocount on;
	exec doc.[Document.Stock.Metadata];
end
go
------------------------------------------------
create or alter procedure doc.[Document.Order.Update]
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
	exec doc.[Document.Order.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go