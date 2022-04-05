/*
initial data
*/

------------------------------------------------
if not exists(select * from cat.Companies)
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);

	insert into cat.Companies (TenantId, [Name]) 
	output inserted.Id into @rtable(id)
	values (1, N'Моє підприємство');
end
go

-- ITEM TREE
if not exists(select * from cat.ItemTree where Id=0)
	insert into cat.ItemTree(TenantId, Id, Parent, [Root], [Name]) 
	values(1, 0, 0, 0, N'Root');
go
-------------------------------------------------
if not exists(select * from cat.ItemTree where Id=1)
	insert into cat.ItemTree(TenantId, Id, Parent, [Root], [Name]) 
	values(1, 1, 0, 0, N'(Default hierarchy)');
go
-------------------------------------------------
-- FormsMenu
begin
	set nocount on;
	declare @fu table(Id nvarchar(32), [Order] int, Category nvarchar(32), [Name] nvarchar(255));
	insert into @fu (Id, [Order], [Category], [Name]) values
		(N'Sales.Order',   10, N'@[Sales]', N'@[Orders]'),
		(N'Sales.Sales',   11, N'@[Sales]', N'@[Sales]'),
		(N'Sales.Payment', 12, N'@[Sales]', N'@[Payment]'),
		(N'Purchase.Purchase', 20, N'@[Purchases]', N'@[Purchase]'),
		(N'Purchase.Stock',    21, N'@[Purchases]', N'@[Warehouse]'),
		(N'Purchase.Payment',  22, N'@[Purchases]', N'@[Payment]');
	merge doc.FormsMenu as t
	using @fu as s on t.Id = s.Id and t.TenantId = 1
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.Category = s.Category
	when not matched by target then insert
		(TenantId, Id, [Name], [Order], Category) values
		(1, s.Id, s.[Name], [Order], Category)
	when not matched by source and t.TenantId = 1 then delete;
end
go
-------------------------------------------------
-- FORMS
begin
	set nocount on;
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
	using @df as s on t.Id = s.Id and t.TenantId = 1
	when matched then update set
		t.[Name] = s.[Name],
		t.[RowKinds] = s.[RowKinds]
	when not matched by target then insert
		(TenantId, Id, [Name], RowKinds) values
		(1, s.Id, s.[Name], RowKinds)
	when not matched by source and t.TenantId = 1 then delete;
end
go


