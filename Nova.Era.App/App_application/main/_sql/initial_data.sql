﻿/*
initial data
*/
------------------------------------------------
-- Default catalogs
create or alter procedure ini.[Cat.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;
	if not exists(select * from cat.Currencies where Id=980 and TenantId = @TenantId)
		insert into cat.Currencies(TenantId, Id, Short, Alpha3, Number3, [Symbol], Denom, [Name]) 
		select @TenantId, Id, Short, Alpha3, Number3, Symbol, Denom, [Name]
			from cat.Currencies where TenantId = 0 and Id = 980;
	-- on create tenant all
	if not exists(select * from cat.ItemTree where TenantId = @TenantId)
		insert into cat.ItemTree(TenantId, Id, [Root], [Parent], [Name]) values (@TenantId, 0, 0, 0, N'ROOT');
end
go
-------------------------------------------------
create or alter procedure ini.[Rep.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	declare @rt table(Id nvarchar(16), [Order] int, [Name] nvarchar(255), UseAccount bit, [UsePlan] bit, UseStock bit, UseCash bit);
	insert into @rt (Id, [Order], [Name], UseAccount, [UsePlan], UseStock, UseCash) values
		(N'by.account', 10, N'@[By.Account]', 1, 0, 0, 0),
		(N'by.plan',    20, N'@[By.Plan]',    0, 1, 0, 0),
		(N'by.stock',   30, N'@[By.Stock]',   0, 0, 1, 0),
		(N'by.cash',    40, N'@[By.Cash]',    0, 0, 0, 0),
		(N'by.settle',  50, N'@[By.Settle]',  0, 0, 0, 0);
	merge rep.RepTypes as t
	using @rt as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.UseAccount = s.UseAccount,
		t.[UsePlan] = s.[UsePlan]
	when not matched by target then insert
		(TenantId, Id, [Name], [Order], UseAccount, [UsePlan]) values
		(@TenantId, s.Id, s.[Name], [Order], UseAccount, [UsePlan])
	when not matched by source and t.TenantId = @TenantId then delete;

	-- FIX ERRORS
	delete from rep.Reports where [File] in (N'cash.rems');

	declare @rf table(Id nvarchar(16), [Order] int, [Type] nvarchar(16), [Url] nvarchar(255), [Name] nvarchar(255));
	insert into @rf (Id, [Type], [Order], [Url], [Name]) values
		-- acc
		(N'acc.date',      N'by.account',  1, N'/reports/account/rto_accdate',  N'Обороти рахунку (дата)'),
		(N'acc.agent',     N'by.account',  2, N'/reports/account/rto_accagent', N'Обороти рахунку (контрагент)'),
		(N'acc.agentcntr', N'by.account',  3, N'/reports/account/rto_accagentcontract', N'Обороти рахунку (контрагент + договір)'),
		(N'acc.respcost',  N'by.account',  4, N'/reports/account/rto_respcost', N'Обороти рахунку (центр відповідальності + стаття витрат)'),
		(N'acc.item',      N'by.account',  5, N'/reports/stock/rto_items',      N'Оборотно сальдова відомість (об''єкт обліку)'),
		-- plan
		(N'plan.turnover', N'by.plan', 1, N'/reports/plan/turnover',    N'Оборотно сальдова відомість'),
		(N'plan.money',    N'by.plan', 2, N'/reports/plan/cashflow',    N'Відомість по грошових коштах'),
		(N'plan.rems',     N'by.plan', 3, N'/reports/plan/itemrems',    N'Залишики на складах'),
		-- cash
		(N'cash.datedoc',  N'by.cash', 1, N'/reports/cash/rto_datedoc', N'Оборотно сальдова відомість (дата + документ)'),
		-- settle
		(N'settle.dateag',   N'by.settle', 1, N'/reports/settle/rto_dateag', N'Оборотно сальдова відомість (дата + контрагент)'),
		-- stock
		(N'stock.remswh',  N'by.stock', 1, N'/reports/stock/rems_wh', N'Залишки на складах');

	merge rep.RepFiles as t
	using @rf as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Url] = s.[Url],
		t.[Order] = s.[Order],
		t.[Type] = s.[Type]
	when not matched by target then insert
		(TenantId, Id, [Name], [Type], [Order], [Url]) values
		(@TenantId, s.Id, s.[Name], s.[Type], [Order], [Url])
	when not matched by source and t.TenantId = @TenantId then delete;
end
go
-------------------------------------------------
-- FormsMenu
create or alter procedure ini.[Forms.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	declare @fu table(Id nvarchar(32), [Order] int, Category nvarchar(32), [Name] nvarchar(255));
	insert into @fu (Id, [Order], [Category], [Name]) values
		(N'Sales.Order',   10, N'@[Sales]', N'@[Orders]'),
		(N'Sales.Sales',   11, N'@[Sales]', N'@[Sales]'),
		(N'Sales.Payment', 12, N'@[Sales]', N'@[Payment]'),
		--
		(N'Purchase.Purchase', 20, N'@[Purchases]',  N'@[Purchase]'),
		(N'Purchase.Stock',    21, N'@[Purchases]',  N'@[Warehouse]'),
		(N'Purchase.Payment',  22, N'@[Purchases]',  N'@[Payment]'),
		--
		(N'Accounting.Bank',   30, N'@[Accounting]', N'@[Bank]'),
		(N'Accounting.Cash',   31, N'@[Accounting]', N'@[CashAccount]');
	merge doc.FormsMenu as t
	using @fu as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.Category = s.Category
	when not matched by target then insert
		(TenantId, Id, [Name], [Order], Category) values
		(@TenantId, s.Id, s.[Name], [Order], Category)
	when not matched by source and t.TenantId = @TenantId then delete;

	-- forms
	declare @df table(id nvarchar(16), [order] int, inout smallint, [url] nvarchar(255), 
		category nvarchar(255), [name] nvarchar(255), hasstate bit);
	insert into @df (id, inout, [order], hasstate, category, [url], [name]) values
		-- Sales
		(N'invoice',    null, 10, 1, N'@[Sales]', N'/document/sales', N'Замовлення клієнта'),
		(N'complcert',  null, 11, 0, N'@[Sales]', N'/document/sales', N'Акт виконаних робіт'),
		(N'waybillout', null, 12, 0, N'@[Sales]', N'/document/sales', N'Продаж товарів/послуг'),
		(N'retcust',    null, 13, 0, N'@[Sales]', N'/document/sales', N'Повернення від покупця'),
		-- Purchase
		(N'invoicein',  null, 20, 1, N'@[Purchases]', N'/document/purchase', N'Замовлення постачальнику'),
		(N'waybillin',  null, 21, 0, N'@[Purchases]', N'/document/purchase', N'Придбання товарів/послуг'),
		(N'retsuppl',   null, 22, 0, N'@[Purchases]', N'/document/purchase', N'Повернення постачальнику'),
		-- Invent
		(N'movebill',   null, 30, 0, N'@[KindStock]', N'/document/invent', N'Внутрішнє переміщення'),
		(N'inventbill', null, 31, 0, N'@[KindStock]', N'/document/invent', N'Інвентарізація'),
		(N'writeoff',   null, 32, 0, N'@[KindStock]', N'/document/invent', N'Акт списання'),
		(N'writeon',    null, 33, 0, N'@[KindStock]', N'/document/invent', N'Акт оприбуткування'),
		-- Money
		(N'payout',    -1,  40, 0, N'@[Money]', N'/document/money', N'Витрата безготівкових коштів'),
		(N'cashout',   -1,  41, 0, N'@[Money]', N'/document/money', N'Витрата готівки'),
		(N'payin',      1,  42, 0, N'@[Money]', N'/document/money', N'Надходження безготівкових коштів'),
		(N'cashin',     1,  43, 0, N'@[Money]', N'/document/money', N'Надходження готівки'),
		(N'cashmove', null, 44, 0, N'@[Money]', N'/document/money', N'Прерахування коштів'),
		(N'cashoff',  -1,   45, 0, N'@[Money]', N'/document/money', N'Списання коштів'),
		-- 
		(N'manufact',  null, 60, 0, N'@[Manufacturing]', N'/manufacturing/document', N'Виробничий акт-звіт');

	merge doc.Forms as t
	using @df as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order],
		t.InOut = s.inout,
		t.[Url] = s.[url],
		t.Category = s.category,
		t.HasState = s.hasstate
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], InOut, Category, [Url], HasState) values
		(@TenantId, s.id, s.[order], s.[name], inout, category, [url], hasstate)
	when not matched by source and t.TenantId = @TenantId then delete;

	-- docstates
	declare @st table(Id bigint, Form nvarchar(16), [Order] int, Kind nchar(1), [Name] nvarchar(255), Color nvarchar(32));
	insert into @st(Id, Form, [Order], Kind, [Name], Color) values
	(10, N'invoice', 10, N'I',  N'Новий', N'blue'),
	(20, N'invoice', 20, N'P',  N'В обробці', N'gold'),
	(30, N'invoice', 30, N'S',  N'Завершено', N'seagreen'),
	(40, N'invoice', 40, N'C',  N'Скасовано', N'red');

	merge doc.DocStates as t
	using @st as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.Kind = s.Kind,
		t.[Color] = s.[Color]
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], Form, Kind, Color) values
		(@TenantId, s.Id, s.[Order], s.[Name], s.Form, s.Kind, s.Color)
	when not matched by source and t.TenantId = @TenantId then delete;

	-- temp
	update doc.Operations set DocumentUrl = f.[Url] + N'/' + f.Id
	from doc.Operations o inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id

	-- form row kinds
	declare @rk table(Id nvarchar(16), [Order] int, Form nvarchar(16), [Name] nvarchar(255));
	insert into @rk([Form], [Order], Id, [Name]) values
	(N'waybillout', 1, N'Stock',   N'@[KindStock]'),
	(N'waybillout', 2, N'Service', N'@[KindServices]'),
	(N'waybillout', 3, N'All',     N'@[KindAllRows]'),
	(N'waybillin',  1, N'Stock',   N'@[KindStock]'),
	(N'waybillin',  2, N'Service', N'@[KindServices]'),
	(N'movebill',   1, N'Stock',   N'@[KindStock]'),
	(N'inventbill', 1, N'Stock',   N'@[KindStock]'),
	(N'writeoff',   1, N'Stock',   N'@[KindStock]'),
	(N'writeon',    1, N'Stock',   N'@[KindStock]'),
	(N'payin',      1, N'', N'Немає рядків'),
	(N'payout',     1, N'', N'Немає рядків'),
	(N'cashin',     1, N'', N'Немає рядків'),
	(N'cashout',    1, N'', N'Немає рядків'),
	(N'cashmove',   1, N'', N'Немає рядків'),
	(N'cashoff',    1, N'', N'Немає рядків'),
	(N'invoice',    1, N'Stock',   N'@[KindStock]'),
	(N'invoice',    2, N'Service', N'@[KindServices]'),
	(N'manufact',   1, N'Stock',   N'@[KindStock]'),
	(N'manufact',   2, N'Product', N'@[KindProd]');

	merge doc.FormRowKinds as t
	using @rk as s on t.Id = s.Id and t.Form = s.Form and t.TenantId = @TenantId
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Order] = s.[Order]
	when not matched by target then insert
		(TenantId, Id, [Form], [Name], [Order]) values
		(@TenantId, s.Id, s.[Form], s.[Name], s.[Order])
	when not matched by source and t.TenantId = @TenantId then delete;

	-- print forms
	declare @pf table(id nvarchar(16), [order] int, category nvarchar(255), [name] nvarchar(255), 
		[url] nvarchar(255), report nvarchar(255));
	insert into @pf (id, [order], category, [name], [url], [report]) values
		-- Sales
		(N'invoice',    1, N'@[Sales]', N'Замовлення клієнта', N'/document/print', N'invoice'),
		(N'waybillout', 2, N'@[Sales]', N'Видаткова накладна', N'/document/print', N'waybillout');

	merge doc.PrintForms as t
	using @pf as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order],
		t.Category = s.category,
		t.[Url] = s.[url],
		t.[Report] = s.[report]
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], Category, [Url], [Report]) values
		(@TenantId, s.id, s.[order], s.[name], category, [url], [report])
	when not matched by source and t.TenantId = @TenantId then delete;

end
go
-------------------------------------------------
-- Contracts
create or alter procedure ini.[Contract.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;
	-- contract kinds
	declare @ck table(Id nvarchar(16), [Order] int, [Name] nvarchar(255));
	insert into @ck(Id, [Order], [Name]) values
	(N'supplier', 1, N'@[ContractKind.Supplier]'),
	(N'customer', 2, N'@[ContractKind.Customer]'),
	(N'other',    9, N'@[ContractKind.Other]');

	merge doc.ContractKinds as t
	using @ck as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Order] = s.[Order]
	when not matched by target then insert
		(TenantId, Id, [Name], [Order]) values
		(@TenantId, s.Id, s.[Name], s.[Order])
	when not matched by source and t.TenantId = @TenantId then delete;
end
go
-------------------------------------------------
-- Operations
create or alter procedure ini.[Operation.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	-- TEMPORARY
	update doc.Operations set Kind = null where Kind like N'%.%';

	-- operation kinds
	declare @ok table(Id nvarchar(16),Factor smallint, [Order] int, [Name] nvarchar(255), Kind nvarchar(16), [Type] nchar(1));
	insert into @ok(Id, Factor, [Order], [Type], [Kind], [Name]) values
	(N'Order',         0, 1, N'B', N'Order',    N'@[OperationKind.Order]'),
	(N'Shipment',      1, 2, N'P', N'Shipment', N'@[OperationKind.Shipment]'),
	(N'RetShipment',  -1, 3, N'P', N'Shipment', N'@[OperationKind.Return]'),
	(N'Payment',       1, 4, N'P', N'Payment',  N'@[OperationKind.Payment]'),
	(N'RetPayment',   -1, 5, N'P', N'Payment',  N'@[OperationKind.RetPayment]');

	merge doc.OperationKinds as t
	using @ok as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set 
		t.Kind = s.Kind,
		t.LinkType = s.[Type],
		t.Factor = s.Factor,
		t.[Name] = s.[Name],
		t.[Order] = s.[Order]
	when not matched by target then insert
		(TenantId, Id, [Name], Kind, LinkType, Factor, [Order]) values
		(@TenantId, s.Id, s.[Name], s.Kind, s.[Type], s.Factor, s.[Order])
	when not matched by source and t.TenantId = @TenantId then delete;
end
go
-------------------------------------------------
-- Widgets
create or alter procedure ini.[Widgets.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	-- 1000 accounting - 1000,
	-- 2000 sales
	-- 3000 purchase
	-- 10000+ modules
	declare @widgets table(Kind nvarchar(16), Category nvarchar(64), Id bigint, rowSpan int, colSpan int, [Name] nvarchar(255), [Url] nvarchar(255), 
		Memo nvarchar(255), Icon nvarchar(32), Params nvarchar(1023));
	insert into @widgets (Id, Kind, Category, colSpan, rowSpan, [Name], [Url], Icon, Memo, Params) values
		(1000, N'Root',       N'@[Accounting]', 5, 3, N'Грошові кошти', N'/accounting/widgets/cashflow', N'chart-column', N'Діаграма руху грошових коштів', null),
		(1001, N'Root',       N'@[Sales]',      2, 1, N'Продажі',       N'/sales/widgets/salesmonth',    N'cart',         N'Продажі за місяць', null),
		--
		(2001, N'Accounting', N'@[Accounting]', 5, 3, N'Грошові кошти', N'/accounting/widgets/cashflow', N'chart-column', N'Діаграма руху грошових коштів', null);
		/*
		(1002, N'Root',       2, 1, N'Widget 2x1', N'/widgets/widget3/index', N'currency-uah', null, null);
		(N'Widget4', 2, 2, N'Widget 2x2', N'/widgets/widget4/index', null, null),
		(N'Widget5', 1, 1, N'Widget 1x1', N'/widgets/widget1/index', null, null),
		(N'Widget6', 2, 1, N'Widget 1x2', N'/widgets/widget2/index', null, null),
		(N'Widget7', 1, 2, N'Widget 2x1', N'/widgets/widget3/index', null, null),
		(N'Widget8', 2, 2, N'Widget 2x2', N'/widgets/widget4/index', null, null);
		*/
	merge app.Widgets as t
	using @widgets as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.rowSpan = s.rowSpan,
		t.colSpan = s.colSpan,
		t.[Url] = s.[Url],
		t.Memo = s.Memo,
		t.Icon = s.Icon,
		t.Kind = s.Kind,
		t.Category = s.Category,
		t.Params = s.Params
	when not matched by target then insert
		(TenantId, Id, Kind, Category, [Name], rowSpan, colSpan, [Url], Memo, Icon, Params) values
		(@TenantId, s.Id, s.Category, s.Kind, s.[Name], s.rowSpan, s.colSpan, s.[Url], s.Memo, s.Icon, s.Params);
end
go
-------------------------------------------------
-- Crm
create or alter procedure ini.[Crm.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	-- (I)nit, (P)rocess, [S]uccess, F(ail)
	declare @ls table(Kind nchar(1), Id bigint, [Order] int, [Name] nvarchar(255), Color nvarchar(32));
	insert into @ls (Kind, Id, [Order], [Name], [Color]) values
		(N'I', 10, 10, N'Новий', N'blue'),
		(N'P', 20, 20, N'В обробці', N'orange'),
		(N'S', 30, 30, N'Успіх', N'seagreen'),
		(N'F', 40, 40, N'Невдача', N'red');
	merge crm.LeadStages as t
	using @ls as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.Kind = s.Kind,
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.[Color] = s.[Color]
	when not matched by target then insert
		(TenantId, Id, Kind, [Name], [Order], [Color]) values
		(@TenantId, s.Id, s.Kind, s.[Name], s.[Order], s.[Color]);
end
go
-------------------------------------------------
-- App
create or alter procedure ini.[App.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;
	declare @ts table(Id bigint, [Order] int, [Name] nvarchar(255), Color nvarchar(32));
	insert into @ts (Id, [Order], [Name], [Color]) values
		(10, 10, N'Нова', N'blue'),
		(20, 20, N'В обробці', N'orange'),
		(30, 30, N'Завершена', N'seagreen'),
		(40, 40, N'Скасована', N'red');
	merge app.TaskStates as t
	using @ts as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.[Color] = s.[Color]
	when not matched by target then insert
		(TenantId, Id, [Name], [Order], [Color]) values
		(@TenantId, s.Id, s.[Name], s.[Order], s.[Color]);
end
go
------------------------------------------------
-- !CHECK startup_mt.sql!
exec ini.[Cat.OnCreateTenant] @TenantId = 1;
exec ini.[Forms.OnCreateTenant] @TenantId = 1;
exec ini.[Rep.OnCreateTenant] @TenantId = 1;
exec ini.[Widgets.OnCreateTenant] @TenantId = 1;
exec ini.[Contract.OnCreateTenant] @TenantId = 1;
exec ini.[Operation.OnCreateTenant] @TenantId = 1;
exec ini.[Crm.OnCreateTenant] @TenantId = 1;
exec ini.[App.OnCreateTenant] @TenantId = 1;
go

