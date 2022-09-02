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
	insert into a2sys.SysParams ([Name], StringValue) values (N'AppTitle', N'Нова Ера');
else
	update a2sys.SysParams set StringValue = N'Нова Ера' where [Name] = N'AppTitle';
go
------------------------------------------------
create or alter procedure a2ui.[Menu.Simple.User.Load]
@TenantId int = 1,
@UserId bigint = null,
@Mobile bit = 0,
@Root bigint = 1
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with RT as (
		select Id=m0.Id, ParentId = m0.Parent, [Level]=0
			from a2ui.Menu m0
			where m0.Id = @Root
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
		(2,  null,  0, N'Start',         null,         null, null),
		(3,  null,  0, N'Init',      null,         null, null),

		(71,    2,  1, N'@[Welcome]',     N'appstart',   N'success-outline', null),
		(72,    3,  1, N'@[AppInit]',     N'appinit',    N'arrow-up', null),

		(10,    1,  10, N'@[Dashboard]',     N'dashboard',   N'dashboard-outline', null),
		(11,    1,  11, N'@[Crm]',           N'crm',         N'share', null),
		(12,    1,  12, N'@[Sales]',         N'sales',       N'shopping', N'border-top'),
		(13,    1,  13, N'@[Purchases]',     N'purchase',    N'cart', null),
		--(14,    1,  14, N'@[Manufacturing]', N'manufacturing',  N'wrench', null),
		(15,    1,  15, N'@[Accounting]',    N'accounting',  N'calc', null),
		--(16,    1,  16, N'@[Payroll]',       N'payroll',  N'calc', null),
		--(17,    1,  17, N'@[Tax]',           N'tax',  N'calc', null),
		(88,    1,  88, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
		(90,    1,  90, N'@[Profile]',        N'profile',   N'user', null),
		-- CRM
		(1101,  11, 11, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		--(1102,  11, 12, N'@[Leads]',          N'lead',      N'users', N'border-top'),
		-- Sales
		(1201,   12, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(120,    12, 11, N'@[Documents]',      null,  null, null),
		(1202,   120, 2, N'@[Orders]',         N'order',     N'task-complete', null),
		(1203,   120, 3, N'@[Sales]',          N'sales',     N'shopping', null),
		(1204,   120, 4, N'@[Payment]',        N'payment',   N'currency-uah', null),
		(121,    12, 12, N'@[PriceLists]', null, null, null),
		(1210,	 121, 11, N'@[Prices]',         N'price',     N'tag-outline', null),
		(122,    12, 12, N'@[Catalogs]',      null,  null, null),
		(1220,   122, 30, N'@[Customers]',      N'agent',     N'users', null),
		(1221,   122, 31, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1222,   122, 32, N'@[Projects]',       N'project',   N'log', null),
		(1223,   122, 33, N'@[Items]',          N'item',      N'package-outline', N'line-top'),
		(1224,   122, 34, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1230,   12, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1231,   12, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Purchase
		(1301,   13, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(130,    13, 11, N'@[Documents]',      null,  null, null),
		(1302,  130, 10, N'@[Purchases]',      N'purchase',  N'cart', null),
		(1303,  130, 11, N'@[Warehouse]',      N'stock',     N'warehouse', null),
		(1304,  130, 12, N'@[Payment]',        N'payment',   N'currency-uah', null),
		--(1310,   13, 20, N'@[Planning]',       N'plan',      N'calendar', N'border-top'),
		--(131,    13, 12, N'@[Prices]', null, null, null),
		--(1311,  131, 10, N'@[PriceDoc]',       N'pricedoc',  N'file', null),
		--(1312,  131, 11, N'@[Prices]',         N'price',     N'tag-outline', null),
		(133,    13, 14, N'@[Catalogs]',  null, null, null),
		(1320,  133, 10, N'@[Suppliers]',      N'agent',     N'users', null),
		(1321,  133, 11, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1322,  133, 12, N'@[Items]',          N'item',      N'package-outline', N'line-top'),
		(1323,  133, 13, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1330,   13, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1331,   13, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Accounting
		(1501,   15, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(150,    15, 11, N'@[Documents]',      null, null, null),
		(1502,  150, 10, N'@[Bank]',           N'bank',   N'bank',  null),
		(1503,  150, 11, N'@[CashAccount]',    N'cash',   N'currency-uah',  null),
		(1504,   15, 12, N'@[AccountPlans]',   N'plan',      N'account',  N'border-top'),
		(153,    15, 15, N'@[Catalogs]',  null, null, null),
		(1505,  153, 10, N'@[BankAccounts]',   N'bankacc',   N'bank', null),
		(1506,	153, 11, N'@[CashAccounts]',   N'cashacc',   N'currency-uah', null),
		(1507,  153, 12, N'@[Agents]',         N'agent',     N'users', null),
		(1508,  153, 13, N'@[Persons]',        N'person',    N'user-role', null),
		(1509,  153, 14, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1510,  153, 15, N'@[Projects]',       N'project',   N'log', null),
		(1511,  153, 16, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1512,   15, 20, N'@[Journal]',        N'journal',   N'file-content',  N'border-top'),
		(1530,   15, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1531,   15, 41, N'@[Service]',        N'service',   N'gear-outline', null),

		-- Settings
		(880,   88, 10, N'@[Dashboard]',    'dashboard', 'dashboard-outline', N'border-bottom'),
		(881,   88, 11, N'@[Settings]',     null, null, null),
		(8811, 881, 10, N'@[AccPolicy]',    N'policy',      N'gear-outline',  null),
		(8812, 881, 10, N'@[AccountPlans]', N'accountplan', N'account',  null),
		(8813, 881, 11, N'@[Operations]',   N'operation',   N'file-content', null),
		(882,   88, 12, N'@[Catalogs]',     null, null, null),
		(8821, 882, 11, N'@[Companies]',    N'company',   N'company', null),
		(8822, 882, 12, N'@[Warehouses]',   N'warehouse', N'warehouse', null),
		(8823, 882, 13, N'@[BankAccounts]', N'bankacc',   N'bank', null),
		(8824, 882, 14, N'@[CashAccounts]', N'cashacc',   N'currency-uah', null),
		(8825, 882, 15, N'@[Agents]',       N'agent',     N'users', N'line-top'),
		(8826, 882, 16, N'@[Persons]',      N'person',    N'user-role', null),
		(8827, 882, 17, N'@[Contracts]',    N'contract',  N'user-image', null),
		(8828, 882, 17, N'@[Projects]',     N'project',   N'log', null),
		(8829, 882, 18, N'@[Items]',        N'item',      N'package-outline', N'line-top'),
		(8830, 882, 19, N'@[CatalogOther]', N'catalog',   N'list', null),
		(883,   88, 13, N'@[Administration]', null, null, null),
		(8831, 883, 16, N'@[Users]',        N'user',    N'user',  null),
		(8850,  88, 20, N'Розробка (debug)',N'develop',   N'switch', N'border-top'),
		(8851,  88, 23, N'Test',            N'test',      N'file', null),
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
	(102, N'Sales', 11, N'@[Items]', N'@[Grouping.Item]', N'/catalog/itemgroup/index', N'list',  N''),
	--(102, N'Sales', 12, N'@[Items]', N'@[Brands]',   N'/catalog/brand/index', N'list',  N''),
	(105, N'Sales', 11, N'@[Prices]', N'@[PriceKinds]',        N'/catalog/pricekind/index', N'list',  N''),

	(200, N'Purchase',   10, N'@[Items]',  N'@[Units]',        N'/catalog/unit/index', N'list',  N''),
	(201, N'Purchase',   11, N'@[Items]',  N'@[Grouping.Item]', N'/catalog/itemgroup/index', N'list',  N''),
	(202, N'Purchase',   12, N'@[Prices]', N'@[PriceKinds]',   N'/catalog/pricekind/index', N'list',  N''),

	-- accounting
	(300, N'Accounting', 10, N'@[Accounting]', N'@[Banks]', N'/catalog/bank/index', N'list',  N''),
	(301, N'Accounting', 11, N'@[Accounting]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N''),
	(305, N'Accounting',  12, N'@[Items]',     N'@[Units]',      N'/catalog/unit/index', N'list',  N''),
	(306, N'Accounting',  13, N'@[Prices]',    N'@[PriceKinds]', N'/catalog/pricekind/index', N'list',  N''),

	-- settings
	(900, N'Settings',  01, N'@[General]',   N'@[Countries]',   N'/catalog/country/index', N'list',  N''),
	(901, N'Settings',  02, N'@[General]',   N'@[RespCenters]', N'/catalog/respcenter/index', N'list',  N''),
	(910, N'Settings',  10, N'@[Accounts]',  N'@[ItemRoles]',   N'/catalog/itemrole/index', N'list',  N''),
	(911, N'Settings',  11, N'@[Accounts]',  N'@[AccKinds]',    N'/catalog/acckind/index', N'list',  N''),
	(915, N'Settings',  12, N'@[Documents]', N'@[Autonums]',    N'/catalog/autonum/index', N'list',  N''),
	(920, N'Settings',  21, N'@[Accounting]', N'@[Banks]',         N'/catalog/bank/index', N'list',  N''),
	(921, N'Settings',  22, N'@[Accounting]', N'@[Currencies]',    N'/catalog/currency/index', N'list',  N''),
	(922, N'Settings',  23, N'@[Accounting]', N'@[CostItems]',     N'/catalog/costitem/index', N'list',  N''),
	(923, N'Settings',  24, N'@[Accounting]', N'@[CashFlowItems]', N'/catalog/cashflowitem/index', N'list',  N''),
	(931, N'Settings',  31, N'@[Items]',  N'@[Grouping.Item]',     N'/catalog/itemgroup/index', N'list',  N''),
	(932, N'Settings',  32, N'@[Items]',  N'@[Categories]',        N'/catalog/itemcategory/index', N'list',  N''),
	(933, N'Settings',  33, N'@[Items]',  N'@[Units]',             N'/catalog/unit/index', N'list',  N''),
	(934, N'Settings',  34, N'@[Items]',  N'@[Brands]',            N'/catalog/brand/index', N'list',  N''),
	(945, N'Settings',  35, N'@[Items]',  N'@[Vendors]',           N'/catalog/vendor/index', N'list',  N''),
	(940, N'Settings',  40, N'@[Prices]', N'@[PriceKinds]',        N'/catalog/pricekind/index', N'list',  N'');

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
