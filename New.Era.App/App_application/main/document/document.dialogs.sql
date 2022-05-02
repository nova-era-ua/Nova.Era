/* Document.Dialogs */
------------------------------------------------
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
------------------------------------------------
create or alter procedure doc.[Document.Transactions.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

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
end
go
