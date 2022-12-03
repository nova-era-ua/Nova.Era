/* Document.Pay */
------------------------------------------------
create or alter procedure doc.[Document.Pay.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(255),
@AccMode nvarchar(16) = N'All',
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Operation bigint = -1,
@Agent bigint = null,
@CashAccount bigint = null,
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
		comp bigint, bafrom bigint, bato bigint, cafrom bigint, cato bigint, base bigint, rowcnt int);

	insert into @docs(id, op, agent, comp, cafrom, cato, base, rowcnt)
	select d.Id, d.Operation, d.Agent, d.Company, d.CashAccFrom, d.CashAccTo, d.Base,
		count(*) over()
	from doc.Documents d
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and d.Operation = ml.Operation
	where d.TenantId = @TenantId and d.Temp = 0 and ml.Menu = @Menu
		and (d.[Date] >= @From and d.[Date] < @end)
		and (@Operation = -1 or d.Operation = @Operation)
		and (@Agent is null or d.Agent = @Agent)
		and (@Company is null or d.Company = @Company)
		and (@CashAccount is null or d.CashAccFrom = @CashAccount or d.CashAccTo = @CashAccount)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'date' then d.[Date]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'date' then d.[Date]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order 
				when N'sum' then d.[Sum]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'sum' then d.[Sum]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order 
				when N'id' then d.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then d.[Id]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order 
				when N'no' then isnull(d.[No], d.SNo)
				when N'memo' then d.Memo
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'no' then isnull(d.[No], d.SNo)
				when N'memo' then d.Memo
			end
		end desc,
		d.Id desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.[Notice], d.SNo, d.[No], d.Done, d.BindKind, d.BindFactor,
		[Operation!TOperation!RefId] = d.Operation, [BaseDoc!TDocBase!RefId] = d.Base,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[CashAccFrom!TCashAccount!RefId] = d.CashAccFrom, [CashAccTo!TCashAccount!RefId] = d.CashAccTo,
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

	with C as (select ca = cafrom from @docs union all select cato from @docs),
	T as (select ca from C group by ca)
	select [!TCashAccount!Map] = null, [Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.[AccountNo],
		Balance = cast(0 as money)
	from cat.CashAccounts ca
		inner join T t on ca.TenantId = @TenantId and ca.Id = ca;

	with T as (select comp from @docs group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	with T as (select base from @docs group by base)
	select [!TDocBase!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], p.[Done], p.[No], p.BindKind, p.BindFactor,
		[OpName] = o.[Name], o.Form, o.DocumentUrl
	from doc.Documents p inner join T on p.TenantId = @TenantId and p.Id = T.base
		inner join doc.Operations o on p.TenantId = o.TenantId and p.Operation = o.Id;

	-- menu
	select [Menu!TMenu!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], FormId = f.Id, FormName = f.[Name],
		o.DocumentUrl
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by f.[Order];

	-- params
	select [Params!TParam!Object] = null, [Menu] = @Menu, AccMode = @AccMode;

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
		[!Documents.CashAccount.Id!Filter] = @CashAccount, [!Documents.CashAccount.Name!Filter] = cat.fn_GetCashAccountName(@TenantId, @CashAccount);
end
go
------------------------------------------------
create or alter procedure doc.[Document.Pay.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Operation bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docform nvarchar(16);
	declare @done bit;

	if @Operation is null
		select @Operation = d.Operation from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id;

	select @docform = o.Form from doc.Operations o where o.TenantId = @TenantId and o.Id = @Operation;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.Notice, d.SNo, d.[No], d.[Sum], d.Done, d.BindKind, d.BindFactor,
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, 
		[CashAccFrom!TCashAccount!RefId] = d.CashAccFrom, [CashAccTo!TCashAccount!RefId] = d.CashAccTo,
		[Contract!TContract!RefId] = d.[Contract], [CashFlowItem!TCashFlowItem!RefId] = d.CashFlowItem,
		[RespCenter!TRespCenter!RefId] = d.RespCenter, [ItemRole!TItemRole!RefId] = d.ItemRole, [Project!TProject!RefId] = d.Project,
		[ParentDoc!TDocBase!RefId] = d.Parent, [BaseDoc!TDocBase!RefId] = d.Base,
		[LinkedDocs!TDocBase!LazyArray] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl,
		[Links!TOpLink!Array] = null
	from doc.Operations o 
	where o.TenantId = @TenantId and o.Id = @Operation;

	select [!TOpLink!Array] = null, [Id!!Id] = ol.Id, ol.Category, ch.[Name], [!TOperation.Links!ParentId] = ol.Parent
	from doc.OperationLinks ol 
		inner join doc.Operations ch on ol.TenantId = ch.TenantId and ol.Operation = ch.Id
	where ol.TenantId = @TenantId and ol.Parent = @Operation;

	select [!TCashAccount!Map] = null, [Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.AccountNo,
		Balance = rep.fn_getCashAccountRem(@TenantId, ca.Id, d.[Date])
	from cat.CashAccounts ca inner join doc.Documents d on d.TenantId = ca.TenantId and ca.Id in (d.CashAccFrom, d.CashAccTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by ca.Id, ca.[Name], ca.AccountNo, d.[Date];

	select [!TCashFlowItem!Map] = null, [Id!!Id] = cf.Id, [Name!!Name] = cf.[Name]
	from cat.CashFlowItems cf inner join doc.Documents d on d.TenantId = cf.TenantId and cf.Id = d.CashFlowItem
	where d.Id = @Id and d.TenantId = @TenantId
	group by cf.Id, cf.[Name];


	exec doc.[Document.MainMaps] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;
	exec doc.[Document.LinkedMaps]  @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

	select [!TDocParent!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], [OperationName] = o.[Name]
	from doc.Documents p inner join doc.Documents d on d.TenantId = p.TenantId and d.Parent = p.Id
	inner join doc.Operations o on p.TenantId = o.TenantId and p.Operation = o.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form], DocumentUrl
	from doc.Operations where TenantId = @TenantId and Form=@docform
	order by Id;

	select [!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind,
		[CostItem!TCostItem!RefId] = ir.CostItem
	from cat.ItemRoles ir inner join doc.Documents d on ir.TenantId = d.TenantId and d.ItemRole = ir.Id
	where ir.TenantId = @TenantId and ir.Void = 0 and d.Id = @Id;

	select [Params!TParam!Object] = null, [Operation] = @Operation;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [!$System!] = null, [!!ReadOnly] = d.Done
	from doc.Documents d where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
drop procedure if exists doc.[Document.Pay.Metadata];
drop procedure if exists doc.[Document.Pay.Update];
drop type if exists doc.[Document.Pay.TableType];
go
------------------------------------------------
create type doc.[Document.Pay.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Sum] money,
	Operation bigint,
	Agent bigint,
	Company bigint,
	CashAccFrom bigint,
	CashAccTo bigint,
	[Contract] bigint,
	[CashFlowItem] bigint,
	RespCenter bigint,
	Memo nvarchar(255),
	Notice nvarchar(255),
	SNo nvarchar(64),
	[No] nvarchar(64),
	ItemRole bigint,
	Project bigint
)
go
------------------------------------------------
create or alter procedure doc.[Document.Pay.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Document doc.[Document.Pay.TableType];
	select [Document!Document!Metadata] = null, * from @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Pay.Update]
@TenantId int = 1,
@UserId bigint,
@Document doc.[Document.Pay.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

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
		t.CashAccFrom = s.CashAccFrom,
		t.CashAccTo = s.CashAccTo,
		t.[Contract] = s.[Contract],
		t.CashFlowItem = s.CashFlowItem,
		t.RespCenter = s.RespCenter,
		t.Project = s.Project,
		t.Memo = s.Memo,
		t.Notice = s.Notice,
		t.[No] = @no,
		t.[SNo] = s.SNo,
		t.ItemRole = s.ItemRole
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, 
			CashAccFrom, CashAccTo, [Contract], CashFlowItem, RespCenter, Project, Memo, Notice, SNo, [No], ItemRole, UserCreated) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, 
			s.CashAccFrom, s.CashAccTo, s.[Contract], s.CashFlowItem, s.RespCenter, s.Project, s.Memo, s.Notice, s.SNo, @no, s.ItemRole, @UserId)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	exec doc.[Document.Pay.Load] @TenantId = @TenantId, 
	@UserId = @UserId, @Id = @id;
end
go

