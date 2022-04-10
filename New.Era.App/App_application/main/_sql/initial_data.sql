/*
initial data
*/
------------------------------------------------
-- Default catalogs
create or alter procedure ini.[Cat.OnCreateTenant]
@TenantId int
as
begin
	if not exists(select * from cat.Companies where TenantId = @TenantId)
		insert into cat.Companies (TenantId, [Name]) values (@TenantId, N'Моє підприємство');
	if not exists(select * from cat.Warehouses where TenantId = @TenantId)
		insert into cat.Warehouses(TenantId, [Name]) values (@TenantId, N'Основний склад');
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
		(N'Purchase.Purchase', 20, N'@[Purchases]', N'@[Purchase]'),
		(N'Purchase.Stock',    21, N'@[Purchases]', N'@[Warehouse]'),
		(N'Purchase.Payment',  22, N'@[Purchases]', N'@[Payment]');
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
	declare @df table(Id nvarchar(16), [Name] nvarchar(255));
	insert into @df (Id, [Name]) values
		-- Sales
		(N'invoice',    N'Замовлення клієнта'),
		(N'waybillout', N'Видаткова накладна'),
		(N'complcert',  N'Акт виконаних робіт'),
		-- 
		(N'waybillin',  N'Прибуткова накладна'),
		--
		(N'payorder',  N'Платіжне доручення'),
		-- 
		(N'manufact',  N'Виробничий акт-звіт');

	merge doc.Forms as t
	using @df as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name]
	when not matched by target then insert
		(TenantId, Id, [Name]) values
		(@TenantId, s.Id, s.[Name])
	when not matched by source and t.TenantId = @TenantId then delete;

	-- form row kinds
	declare @rk table(Id nvarchar(16), [Order] int, Form nvarchar(16), [Name] nvarchar(255));
	insert into @rk([Form], [Order], Id, [Name]) values
	(N'waybillout', 1, N'', N'Всі рядки'),
	(N'invoice',    1, N'', N'Всі рядки'),
	(N'manufact',   1, N'', N'Всі рядки'),
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



