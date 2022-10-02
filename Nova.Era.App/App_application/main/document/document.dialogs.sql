/* Document.Dialogs */
------------------------------------------------
/*
здесь было с УЧЕТОМ аналитики по счетам!
create or alter view doc.[view.Document.Transactions]
as
select [!TTransPart!Array] = null, [Id!!Id] = j.Id,
	[Account.Code!TAccount!] = a.Code, j.[Sum], j.Qty,
	[Item.Id!TItem!Id] = i.Id, [Item.Name!TItem] = i.[Name],
	[Warehouse.Id!TWarehouse!Id] = w.Id, [Warehouse.Name!TWarehouse] = w.[Name],
	[Agent.Id!TAgent!Id] = g.Id, [Agent.Name!TAgent] = g.[Name],
	[CashAcc.Id!TCashAcc!Id] = ca.Id, [CashAcc.Name!TCashAcc] = ca.[Name], 
	[CashAcc.No!TCashAcc!] = ca.AccountNo, [CashAcc.IsCash!TCashAcc!] = ca.IsCashAccount,
	[Contract.Id!TContract!Id] = c.Id, [Contract.Name!TContract!Name] = c.[Name],
	[CashFlowItem.Id!TCashFlowItem!Id] = cf.Id, [CashFlowItem.Name!TCashFlowItem!Name] = cf.[Name],
	[CostItem.Id!TCostItem!Id] = ci.Id, [CostItem.Name!TCostItem!Name] = ci.[Name],
	[RespCenter.Id!TRespCenter!Id] = rc.Id, [RespCenter.Name!TRespCenter!Name] = rc.[Name],
	[!TenantId] = j.TenantId, [!Document] = j.Document, [!DtCt] = j.DtCt, [!TrNo] = j.TrNo, [!RowNo] = j.RowNo
from jrn.Journal j 
	inner join acc.Accounts a on j.TenantId = a.TenantId and j.Account = a.Id
	left join cat.Items i on j.TenantId = i.TenantId and j.Item = i.Id and a.IsItem = 1
	left join cat.Warehouses w on j.TenantId = w.TenantId and j.Warehouse = w.Id and a.IsWarehouse = 1
	left join cat.Agents g on j.TenantId = g.TenantId and j.Agent = g.Id and a.IsAgent = 1
	left join doc.Contracts c on j.TenantId = c.TenantId and j.[Contract] = c.Id and a.IsContract = 1
	left join cat.CashAccounts ca on j.TenantId = ca.TenantId and j.CashAccount = ca.Id and (a.IsCash = 1 or a.IsBankAccount = 1)
	left join cat.CashFlowItems cf on j.TenantId = cf.TenantId and j.CashFlowItem = cf.Id  and (a.IsCash = 1 or a.IsBankAccount = 1)
	left join cat.CostItems ci on j.TenantId = ci.TenantId and j.CostItem = ci.Id and a.IsCostItem = 1
	left join cat.RespCenters rc on j.TenantId = rc.TenantId and j.RespCenter = rc.Id and a.IsRespCenter = 1
go
*/

create or alter view doc.[view.Document.Transactions]
as
select [!TTransPart!Array] = null, [Id!!Id] = j.Id,
	[Account.Code!TAccount!] = a.Code, j.[Sum], j.Qty,
	[Item!TItem!RefId] = j.Item, [Warehouse!TWarehouse!RefId] = j.Warehouse,
	[Agent!TAgent!RefId] = j.Agent,
	[CashAcc.Id!TCashAcc!Id] = ca.Id, [CashAcc.Name!TCashAcc] = ca.[Name], 
	[CashAcc.No!TCashAcc!] = ca.AccountNo, [CashAcc.IsCash!TCashAcc!] = ca.IsCashAccount,
	[Contract.Id!TContract!Id] = c.Id, [Contract.Name!TContract!Name] = c.[Name],
	[CashFlowItem.Id!TCashFlowItem!Id] = cf.Id, [CashFlowItem.Name!TCashFlowItem!Name] = cf.[Name],
	[CostItem!TCostItem!RefId] = j.CostItem, [RespCenter!TRespCenter!RefId] = j.RespCenter,
	[Company!TCompany!RefId] = j.Company,
	[!TenantId] = j.TenantId, [!Document] = j.Document, [!DtCt] = j.DtCt, [!TrNo] = j.TrNo, [!RowNo] = j.RowNo
from jrn.Journal j 
	inner join acc.Accounts a on j.TenantId = a.TenantId and j.Account = a.Id
	left join doc.Contracts c on j.TenantId = c.TenantId and j.[Contract] = c.Id and a.IsContract = 1
	left join cat.CashAccounts ca on j.TenantId = ca.TenantId and j.CashAccount = ca.Id and (a.IsCash = 1 or a.IsBankAccount = 1)
	left join cat.CashFlowItems cf on j.TenantId = cf.TenantId and j.CashFlowItem = cf.Id  and (a.IsCash = 1 or a.IsBankAccount = 1)
go
------------------------------------------------
create or alter procedure doc.[Document.Transactions.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @refs table(comp bigint, item bigint, respcenter bigint, costitem bigint, 
		account bigint, wh bigint, agent bigint, [contract] bigint, cashacc bigint, cashflowitem bigint,
		project bigint);

	select [Transactions!TTrans!Array] = null,
		[Id!!Id] = TrNo, [Dt!TTransPart!Array] = null, [Ct!TTransPart!Array] = null
	from jrn.Journal j
	where j.TenantId = @TenantId and j.Document = @Id
	group by [TrNo]
	order by TrNo;

	-- dt
	select *, [!TTrans.Dt!ParentId] = [!TrNo]
	from doc.[view.Document.Transactions]
	where [!TenantId] = @TenantId and [!Document] = @Id and [!DtCt] = 1
	order by [!RowNo];

	-- ct
	select *, [!TTrans.Ct!ParentId] = [!TrNo]
	from doc.[view.Document.Transactions]
	where [!TenantId] = @TenantId and [!Document] = @Id and [!DtCt] = -1
	order by [!RowNo];

	-- store
	select [StoreTrans!TStoreTrans!Array] = null, [Id!!Id] = Id, Dir, Qty, [Sum],
		[Company!TCompany!RefId] = Company, [Item!TItem!RefId] = Item, [Warehouse!TWarehouse!RefId] = Warehouse,
		[CostItem!TCostItem!RefId] = CostItem, [RespCenter!TRespCenter!RefId] = RespCenter,
		[Agent!TAgent!RefId] = Agent, [Contract!TContract!RefId] = [Contract],
		[Project!TProject!RefId] = Project
	from jrn.StockJournal
	where TenantId = @TenantId and [Document] = @Id
	order by Dir;

	-- cash
	select [CashTrans!TCashTrans!Array] = null, [Id!!Id] = Id, InOut, [Sum],
		[Company!TCompany!RefId] = Company, [CashAccount!TCashAccount!RefId] = CashAccount,
		[CashFlowItem!TCashFlowItem!RefId] = CashFlowItem, [RespCenter!TRespCenter!RefId] = RespCenter,
		[Agent!TAgent!RefId] = Agent, [Contract!TContract!RefId] = [Contract],
		[Project!TProject!RefId] = Project
	from jrn.CashJournal
	where TenantId = @TenantId and [Document] = @Id;

	-- settle
	select [SettleTrans!TSettleTrans!Array] = null, [Id!!Id] = Id, IncDec, [Sum],
		[Company!TCompany!RefId] = Company,[RespCenter!TRespCenter!RefId] = RespCenter,
		[Agent!TAgent!RefId] = Agent, [Contract!TContract!RefId] = [Contract],
		[Project!TProject!RefId] = Project
	from jrn.SettleJournal
	where TenantId = @TenantId and [Document] = @Id;

	-- maps
	insert into @refs(comp, item, costitem, respcenter, agent, wh, [contract], cashacc, project)
	select Company, Item, CostItem, RespCenter, Agent, Warehouse, [Contract], CashAccount, Project
	from jrn.Journal
	where TenantId = @TenantId and Document = @Id;

	insert into @refs(comp, item, costitem, respcenter, wh, agent, [contract], project)
	select Company, Item, CostItem, RespCenter, Warehouse, Agent, [Contract], Project
	from jrn.StockJournal
	where TenantId = @TenantId and Document = @Id;
	
	insert into @refs(comp, cashflowitem, respcenter, agent, [contract], cashacc, project)
	select Company, CashFlowItem, RespCenter, Agent, [Contract], CashAccount, Project
	from jrn.CashJournal
	where TenantId = @TenantId and Document = @Id;

	with TC as (select comp from @refs group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join TC t on c.TenantId = @TenantId and c.Id = t.comp;

	with TCA as (select cashacc from @refs group by cashacc)
	select [!TCashAccount!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.CashAccounts c inner join TCA t on c.TenantId = @TenantId and c.Id = t.cashacc;

	with TW as (select wh from @refs group by wh)
	select [!TWarehouse!Map] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name]
	from cat.Warehouses w inner join TW t on w.TenantId = @TenantId and w.Id = t.wh;

	with TI as (select item from @refs group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name]
	from cat.Items i inner join TI t on i.TenantId = @TenantId and i.Id = t.item;

	with TR as (select respcenter from @refs group by respcenter)
	select [!TRespCenter!Map] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
	from cat.RespCenters r inner join TR t on r.TenantId = @TenantId and r.Id = t.respcenter;

	with TA as (select agent from @refs group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA t on a.TenantId = @TenantId and a.Id = t.agent;

	with TCF as (select cashflowitem from @refs group by cashflowitem)
	select [!TCashFlowItem!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.CashFlowItems c inner join TCF t on c.TenantId = @TenantId and c.Id = t.cashflowitem;

	with TP as (select project from @refs group by project)
	select [!TProject!Map] = null, [Id!!Id] = p.Id, [Name!!Name] = p.[Name]
	from cat.Projects p inner join TP t on p.TenantId = @TenantId and p.Id = t.project;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Base.Select.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Agent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;	
	declare @op bigint, @baseop bigint;

	select @op = Operation from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	select @baseop = ol.Parent from doc.OperationLinks ol
	inner join doc.Operations op on ol.TenantId = op.TenantId and ol.Parent = op.Id
	inner join doc.OperationKinds pk on ol.TenantId = pk.TenantId and op.Kind = pk.Id
	and pk.LinkType = N'B' and ol.Operation = @op;

	declare @docs table (id bigint, agent bigint);
	insert into @docs (id, agent) 
	select Id, Agent from doc.Documents d
	where TenantId = @TenantId and Operation = @baseop and
		(@Agent is null or d.Agent = @Agent);		

	-- field set as TLinkedDoc
	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[No], d.SNo, d.[Date], d.[Sum], d.[Memo],
		d.Done, OpName = o.[Name], o.DocumentUrl, o.Form,
		[Agent!TAgent!RefId] = d.Agent, [LinkedDocs!TDocBase!Array] = null
	from doc.Documents d inner join @docs t on d.TenantId = @TenantId and d.Id = t.id
	inner join doc.Operations o on o.TenantId = d.TenantId and d.Operation = o.Id;

	-- arrays
	-- from BASE!!!
	select [!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done], d.BindKind, d.BindFactor,
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Base
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and t.id = d.Base
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Base = t.id;

	with T as (
		select agent from @docs group by agent
	)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from T inner join cat.Agents a on T.agent = a.Id and a.TenantId = @TenantId;

	-- filters
	select [!$System!] = null,
		[!Documents.Agent.Id!Filter] = @Agent, [!Documents.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent);

	/*
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
end
go
