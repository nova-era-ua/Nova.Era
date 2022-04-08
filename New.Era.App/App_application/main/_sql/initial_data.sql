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

	declare @df table(Id nvarchar(16), [Name] nvarchar(255), RowKinds nvarchar(255));
	insert into @df (Id, [Name], RowKinds) values
		-- Sales
		(N'invoice',    N'Замовлення клієнта', null),
		(N'waybillout', N'Видаткова накладна', null),
		(N'complcert',  N'Акт виконаних робіт', null),
		-- 
		(N'waybillin',  N'Прибуткова накладна', null),
		--
		(N'payorder',  N'Платіжне доручення', null),
		-- 
		(N'manufact',  N'Виробничий акт-звіт', N'Product,Stock');

	merge doc.Forms as t
	using @df as s on t.Id = s.Id and t.TenantId = 0
	when matched then update set
		t.[Name] = s.[Name],
		t.[RowKinds] = s.[RowKinds]
	when not matched by target then insert
		(TenantId, Id, [Name], RowKinds) values
		(@TenantId, s.Id, s.[Name], RowKinds)
	when not matched by source and t.TenantId = @TenantId then delete;
end
go
------------------------------------------------
exec ini.[Cat.OnCreateTenant] @TenantId = 1;
exec ini.[Forms.OnCreateTenant] @TenantId = 1;
go



