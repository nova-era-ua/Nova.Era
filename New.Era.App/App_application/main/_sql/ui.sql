/*
user interface
*/
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Catalog')
create table a2ui.[Catalog]
(
	Id int not null
		constraint PK_Catalog primary key,
	Menu nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Icon] nvarchar(16),
	[Url] nvarchar(255),
	[Order] int,
	[Category] nvarchar(16)
);
go
------------------------------------------------
if not exists(select * from a2sys.SysParams where [Name] = N'NavBarMode')
	insert into a2sys.SysParams ([Name], StringValue) values (N'NavBarMode', N'Menu');
go
------------------------------------------------
if not exists(select * from a2sys.SysParams where [Name] = N'SideBarMode')
	insert into a2sys.SysParams ([Name], StringValue) values (N'SideBarMode', N'Normal');
go
------------------------------------------------
if not exists(select * from a2sys.SysParams where [Name] = N'AppTitle')
	insert into a2sys.SysParams ([Name], StringValue) values (N'AppTitle', N'New Era');
go
------------------------------------------------
create or alter procedure a2ui.[Menu.Simple.User.Load]
@TenantId int = 1,
@UserId bigint = null,
@Mobile bit = 0
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @RootId bigint;
	set @RootId = 1;

	with RT as (
		select Id=m0.Id, ParentId = m0.Parent, [Level]=0
			from a2ui.Menu m0
			where m0.Id = @RootId
		union all
		select m1.Id, m1.Parent, RT.[Level]+1
			from RT inner join a2ui.Menu m1 on m1.Parent = RT.Id
	)
	select [Menu!TMenu!Tree] = null, [Id!!Id]=RT.Id, [!TMenu.Menu!ParentId]=RT.ParentId,
		[Menu!TMenu!Array] = null,
		m.Name, m.Url, m.Icon, m.[Description], m.Help, m.Params, m.ClassName
	from RT 
		inner join a2ui.Menu m on RT.Id=m.Id
	order by RT.[Level], m.[Order], RT.[Id];

	-- system parameters
	select [SysParams!TParam!Object]= null, [AppTitle], [AppSubTitle], [SideBarMode], [NavBarMode], [Pages]
	from (select [Name], [Value]=StringValue from a2sys.SysParams) as s
		pivot (min([Value]) for [Name] in ([AppTitle], [AppSubTitle], [SideBarMode], [NavBarMode], [Pages])) as p;

end
go
------------------------------------------------
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @menu a2ui.[MenuModule.TableType];
	truncate table a2security.[Menu.Acl];

	insert into @menu(Id, Parent, [Order], [Name], [Url], Icon, ClassName) 
	values
		(1,  null,  0, N'Main',         null,         null, null),
		(10,    1,  10, N'@[Dashboard]',     N'dashboard',   N'dashboard-outline', null),
		--(11,    1,  11, N'@[Crm]',           N'crm',         N'share', null),
		(12,    1,  12, N'@[Sales]',         N'sales',       N'shopping', N'border-top'),
		(13,    1,  13, N'@[Purchases]',     N'purchase',    N'cart', null),
		--(14,    1,  14, N'@[Manufacturing]', N'manufacturing',  N'wrench', null),
		(15,    1,  15, N'@[Accounting]',    N'accounting',  N'calc', null),
		--(16,    1,  16, N'@[Payroll]',       N'payroll',  N'calc', null),
		--(17,    1,  17, N'@[Tax]',           N'tax',  N'calc', null),
		(88,    1,  88, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
		(90,    1,  90, N'@[Profile]',        N'profile',   N'user', null),
		-- CRM
		--(1101,  11, 11, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		--(1102,  11, 12, N'@[Leads]',          N'lead',      N'users', N'border-top'),
		-- Sales
		(1201,   12, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1202,   12, 12, N'@[Orders]',         N'order',     N'task-complete', N'border-top'),
		(1203,   12, 13, N'@[Sales]',          N'sales',     N'shopping', null),
		(1204,   12, 14, N'@[Payment]',        N'payment',   N'currency-uah', null),
		(1220,   12, 30, N'@[Customers]',      N'agent',     N'users', N'border-top'),
		(1221,   12, 31, N'@[Items]',          N'item',      N'package-outline', null),
		(1222,   12, 32, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1230,   12, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1231,   12, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Purchase
		(1301,   13, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1302,   13, 11, N'@[Purchases]',      N'purchase',  N'cart', N'border-top'),
		(1303,   13, 12, N'@[Warehouse]',      N'stock',     N'warehouse', null),
		(1304,   13, 13, N'@[Payment]',        N'payment',   N'currency-uah', null),
		--(1310,   13, 20, N'@[Planning]',       N'plan',      N'calendar', N'border-top'),
		(1311,   13, 21, N'@[Prices]',         N'price',     N'chart-column', N'border-top'),
		(1320,   13, 30, N'@[Suppliers]',      N'agent',     N'users', N'border-top'),
		(1321,   13, 31, N'@[Items]',          N'item',      N'package-outline', null),
		(1322,   13, 32, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1330,   13, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1331,   13, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Accounting
		(1501,   15, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1502,   15, 11, N'@[BankAccounts]',   N'bankacc',   N'bank',  N'border-top'),
		(1503,   15, 12, N'@[AccountPlans]',   N'plan',      N'account',  N'border-top'),
		(1504,   15, 13, N'@[Agents]',         N'agent',     N'users',  null),
		(1505,   15, 14, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1506,   15, 15, N'@[Journal]',        N'journal',   N'file-content',  N'border-top'),
		(1530,   15, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1531,   15, 41, N'@[Service]',        N'service',   N'gear-outline', null),

		-- Settings
		(8811,  88, 11, N'@[Companies]',  N'company',   N'company', null),
		(8812,  88, 12, N'@[Warehouses]', N'warehouse', N'warehouse', null),
		(8813,  88, 13, N'@[Users]',     N'user',    N'user',    N'border-top'),
		(8814,  88, 14, N'@[AccountPlans]',  N'accountplan', N'account',      N'border-top'),
		(8815,  88, 15, N'@[Operations]',   N'operation',   N'file-content', null),
		-- Profile
		(9001,  90, 10, N'@[Defaults]',    N'default',   N'list', null);

	exec a2ui.[MenuModule.Merge] @menu, 1, 9999;
end
go
-------------------------------------------------
-- Catalog
begin
	set nocount on;
	declare @cat table(Id int, Menu nvarchar(16), [Name] nvarchar(255), 
		[Order] int, Category nvarchar(32), [Memo] nvarchar(255), [Url] nvarchar(255), Icon nvarchar(16));
	insert into @cat (Id, Menu, [Order], [Category], [Name], [Url], Icon, Memo) values
	(100, N'Sales', 10, N'@[Items]', N'@[Units]',    N'/catalog/unit/index', N'list',  N''),
	--(101, N'Sales', 11, N'@[Items]', N'@[Vendors]',  N'/catalog/vendor/index', N'list',  N''),
	--(102, N'Sales', 12, N'@[Items]', N'@[Brands]',   N'/catalog/brand/index', N'list',  N''),

	(200, N'Purchase',   10, N'@[Items]',  N'@[Units]',      N'/catalog/unit/index', N'list',  N''),
	(201, N'Purchase',   10, N'@[Items]',  N'@[PriceLists]', N'/catalog/pricelist/index', N'list',  N''),
	-- accounting
	(300, N'Accounting', 10, N'@[Accounting]', N'@[Banks]', N'/catalog/bank/index', N'list',  N''),
	(301, N'Accounting', 10, N'@[Accounting]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N'');

	merge a2ui.[Catalog] as t
	using @cat as s on t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.Category = s.Category,
		t.Menu = s.Menu,
		t.Memo = s.Memo,
		t.[Url] = s.[Url],
		t.Icon = s.Icon
	when not matched by target then insert
		(Id, [Name], [Order], Category, Menu, Memo, [Url], Icon) values
		(s.Id, s.[Name], [Order], Category, Menu, Memo, [Url], Icon)
	when not matched by source then delete;
end
go
-------------------------------------------------
create or alter procedure a2ui.[Catalog.Other.Index]
@TenantId int = 1,
@UserId bigint = null,
@Mobile bit = 0,
@Menu nvarchar(16)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Catalog!TCatalog!Array] = null, [Id!!Id] = Id,
		[Name], [Memo], Icon, [Url], Category
	from a2ui.[Catalog]
	where Menu = @Menu order by [Order];
end
go
