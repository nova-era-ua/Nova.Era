/*
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

	declare @rt table(Id nvarchar(16), [Order] int, [Name] nvarchar(255), UseAccount bit, [UsePlan] bit);
	insert into @rt (Id, [Order], [Name], UseAccount, [UsePlan]) values
		(N'by.account', 10, N'@[By.Account]', 1, 0),
		(N'by.plan',    20, N'@[By.Plan]',    0, 1)
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

	declare @rf table(Id nvarchar(16), [Order] int, [Type] nvarchar(16), [Url] nvarchar(255), [Name] nvarchar(255));
	insert into @rf (Id, [Type], [Order], [Url], [Name]) values
		(N'acc.date',      N'by.account',  1, N'/reports/account/rto_accdate', N'Обороти рахунку (дата)'),
		(N'acc.agent',     N'by.account',  2, N'/reports/account/rto_accagent', N'Обороти рахунку (контрагент)'),
		(N'acc.agentcntr', N'by.account',  3, N'/reports/account/rto_accagentcontract', N'Обороти рахунку (контрагент+договір)'),
		(N'acc.respcost',  N'by.account',  4, N'/reports/account/rto_respcost', N'Обороти рахунку (центр відповідальності+стаття витрат)'),
		(N'acc.item',      N'by.account',  5, N'/reports/stock/rto_items', N'Оборотно сальдова відомість (об''єкт обліку)'),
		(N'plan.turnover', N'by.plan', 1, N'/reports/plan/turnover',  N'Оборотно сальдова відомість'),
		(N'plan.money',    N'by.plan', 2, N'/reports/plan/cashflow',  N'Відомість по грошових коштах'),
		(N'plan.rems',     N'by.plan', 2, N'/reports/plan/itemrems',  N'Залишики на складах');

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
	declare @df table(id nvarchar(16), [order] int, inout smallint, [url] nvarchar(255), category nvarchar(255), [name] nvarchar(255));
	insert into @df (id, inout, [order], category, [url], [name]) values
		-- Sales
		(N'invoice',    null, 1, N'@[Sales]', N'/document/sales', N'Замовлення клієнта'),
		(N'complcert',  null, 2, N'@[Sales]', N'/document/sales', N'Акт виконаних робіт'),
		(N'waybillout', null, 3, N'@[Sales]', N'/document/sales', N'Продаж товарів/послуг'),
		-- 
		(N'waybillin',  null, 4, N'@[Purchases]', N'/document/purchase', N'Покупка товарів/послуг'),
		--
		(N'movebill',   null, 5, N'@[KindStock]', N'/document/invent', N'Внутрішнє переміщення'),
		(N'inventbill', null, 6, N'@[KindStock]', N'/document/invent', N'Інвентарізація'),
		(N'writeoff',   null, 7, N'@[KindStock]', N'/document/invent', N'Акт списання'),
		(N'writeon',    null, 8, N'@[KindStock]', N'/document/invent', N'Акт оприбуткування'),
		--
		(N'payout',    -1,  10, N'@[Money]', N'/document/money', N'Витрата безготівкових коштів'),
		(N'cashout',   -1,  11, N'@[Money]', N'/document/money', N'Витрата готівки'),
		(N'payin',      1,  12, N'@[Money]', N'/document/money', N'Надходження безготівкових коштів'),
		(N'cashin',     1,  13, N'@[Money]', N'/document/money', N'Надходження готівки'),
		(N'cashmove', null, 14, N'@[Money]', N'/document/money', N'Прерахування коштів'),
		(N'cashoff',  -1,   15, N'@[Money]', N'/document/money', N'Списання коштів'),
		-- 
		(N'manufact',  null, 20, N'@[Manufacturing]', N'/manufacturing/document', N'Виробничий акт-звіт');

	merge doc.Forms as t
	using @df as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order],
		t.InOut = s.inout,
		t.[Url] = s.[url],
		t.Category = s.category
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], InOut, Category, [Url]) values
		(@TenantId, s.id, s.[order], s.[name], inout, category, [url])
	when not matched by source and t.TenantId = @TenantId then delete;

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
------------------------------------------------
exec ini.[Cat.OnCreateTenant] @TenantId = 1;
exec ini.[Forms.OnCreateTenant] @TenantId = 1;
exec ini.[Rep.OnCreateTenant] @TenantId = 1;
go


