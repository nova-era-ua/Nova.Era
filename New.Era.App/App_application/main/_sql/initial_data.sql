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
	if not exists(select * from cat.Companies where TenantId = @TenantId)
		insert into cat.Companies (TenantId, [Name]) values (@TenantId, N'Моє підприємство');
	if not exists(select * from cat.Warehouses where TenantId = @TenantId)
		insert into cat.Warehouses(TenantId, [Name]) values (@TenantId, N'Основний склад');
	if not exists(select * from cat.Currencies where Id=980)
		insert into cat.Currencies(TenantId, Id, Short, Alpha3, Number3, [Char], Denom, [Name]) values
			(@TenantId, 980, N'грн', N'UAH', N'980', N'₴', 1, N'Українська гривня');
end
go
-------------------------------------------------
-- FormsMenu
create or alter procedure ini.[Forms.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;
	-- for ALL tenants (Id = 0)
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
	using @fu as s on t.Id = s.Id and t.TenantId = 0
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.Category = s.Category
	when not matched by target then insert
		(TenantId, Id, [Name], [Order], Category) values
		(@TenantId, s.Id, s.[Name], [Order], Category)
	when not matched by source and t.TenantId = @TenantId then delete;

	-- forms
	declare @df table(id nvarchar(16), [order] int, [name] nvarchar(255));
	insert into @df (id, [order], [name]) values
		-- Sales
		(N'invoice',    1, N'Замовлення клієнта'),
		(N'complcert',  2, N'Акт виконаних робіт'),
		-- 
		(N'waybillin',  3, N'Надходшення запасів'),
		(N'waybillout', 3, N'Видаткова накладна'),
		--
		(N'payout',    4, N'Витрата безготівкових коштів'),
		(N'payin',     5, N'Надходження безготівкових коштів'),
		(N'cashin',    6, N'Надходження готівки'),
		(N'cashout',   7, N'Витрата готівки'),
		-- 
		(N'manufact',  8, N'Виробничий акт-звіт');

	merge doc.Forms as t
	using @df as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order]
	when not matched by target then insert
		(TenantId, Id, [Order], [Name]) values
		(@TenantId, s.id, s.[order], s.[name])
	when not matched by source and t.TenantId = @TenantId then delete;

	-- form row kinds
	declare @rk table(Id nvarchar(16), [Order] int, Form nvarchar(16), [Name] nvarchar(255));
	insert into @rk([Form], [Order], Id, [Name]) values
	(N'waybillout', 1, N'', N'Всі рядки'),
	(N'waybillin',  1, N'', N'Всі рядки'),
	(N'payin',      1, N'', N'Немає рядків'),
	(N'payout',     1, N'', N'Немає рядків'),
	(N'cashin',     1, N'', N'Немає рядків'),
	(N'cashout',    1, N'', N'Немає рядків'),
	(N'invoice',    1, N'', N'Всі рядки'),
	(N'manufact',   2, N'Stock', N'Запаси'),
	(N'manufact',   3, N'Product', N'Продукція');

	merge doc.FormRowKinds as t
	using @rk as s on t.Id = s.Id and t.Form = s.Form and t.TenantId = @TenantId
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Order] = s.[Order]
	when not matched by target then insert
		(TenantId, Id, [Form], [Name], [Order]) values
		(@TenantId, s.Id, s.[Form], s.[Name], s.[Order])
	when not matched by source and t.TenantId = @TenantId then delete;

end
go
------------------------------------------------
exec ini.[Cat.OnCreateTenant] @TenantId = 1;
exec ini.[Forms.OnCreateTenant] @TenantId = 1;
go



