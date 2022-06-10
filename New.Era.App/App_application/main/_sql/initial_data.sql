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
	if not exists(select * from cat.Companies where TenantId = @TenantId and Id = 10)
		insert into cat.Companies (TenantId, Id, [Name]) values (@TenantId, 10, N'Моє підприємство');
	if not exists(select * from cat.Warehouses where TenantId = @TenantId and Id = 10)
		insert into cat.Warehouses(TenantId, Id, [Name]) values (@TenantId, 10, N'Основний склад');
	if not exists(select * from cat.Currencies where Id=980 and TenantId = @TenantId)
		insert into cat.Currencies(TenantId, Id, Short, Alpha3, Number3, [Symbol], Denom, [Name]) values
			(@TenantId, 980, N'грн', N'UAH', N'980', N'₴', 1, N'Українська гривня');
	if not exists(select * from cat.CashAccounts where TenantId = @TenantId and Id = 10 and IsCashAccount = 1)
		insert into cat.CashAccounts(TenantId, Id, Company, Currency, [Name], IsCashAccount) values (@TenantId, 10, 10, 980, N'Основна каса', 1);
	if not exists(select * from cat.CashAccounts where TenantId = @TenantId and Id = 11 and IsCashAccount = 0)
		insert into cat.CashAccounts(TenantId, Id, Company, Currency, [Name], AccountNo, IsCashAccount) values (@TenantId, 11, 10, 980, N'Основний рахунок', N'<номер рахунку>', 0);
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
		(N'acc.agentcntr', N'by.account',  2, N'/reports/account/rto_accagentcontract', N'Обороти рахунку (контрагент+договір)'),
		(N'acc.item',      N'by.account',  3, N'/reports/stock/rto_items', N'Оборотно сальдова відомість (об''єкт обліку)'),
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
	declare @df table(id nvarchar(16), [order] int, inout smallint, [name] nvarchar(255));
	insert into @df (id, [order], inout, [name]) values
		-- Sales
		(N'invoice',    null, 1, N'Замовлення клієнта'),
		(N'complcert',  null, 2, N'Акт виконаних робіт'),
		-- 
		(N'waybillin',  null, 3, N'Покупка товарів/послуг'),
		(N'waybillout', null, 4, N'Продаж товарів/послуг'),
		--
		(N'movebill',   null, 5, N'Внутрішнє переміщення'),
		--
		(N'payout',    -1, 6, N'Витрата безготівкових коштів'),
		(N'payin',      1, 7, N'Надходження безготівкових коштів'),
		(N'cashout',   -1, 8, N'Витрата готівки'),
		(N'cashin',     1, 9, N'Надходження готівки'),
		-- 
		(N'manufact',  null, 10, N'Виробничий акт-звіт');

	merge doc.Forms as t
	using @df as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order],
		t.InOut = s.inout
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], InOut) values
		(@TenantId, s.id, s.[order], s.[name], inout)
	when not matched by source and t.TenantId = @TenantId then delete;

	-- form row kinds
	declare @rk table(Id nvarchar(16), [Order] int, Form nvarchar(16), [Name] nvarchar(255));
	insert into @rk([Form], [Order], Id, [Name]) values
	(N'waybillout', 1, N'Stock',   N'@[KindStock]'),
	(N'waybillout', 2, N'Service', N'@[KindServices]'),
	(N'waybillout', 3, N'All',     N'@[KindAllRows]'),
	(N'waybillin',  1, N'Stock',   N'@[KindStock]'),
	(N'waybillin',  2, N'Service', N'@[KindServices]'),
	(N'movebill',   1, N'Stock',   N'@[KindStock]'),
	(N'payin',      1, N'', N'Немає рядків'),
	(N'payout',     1, N'', N'Немає рядків'),
	(N'cashin',     1, N'', N'Немає рядків'),
	(N'cashout',    1, N'', N'Немає рядків'),
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


