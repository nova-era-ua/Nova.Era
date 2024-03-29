﻿/*
user interface
*/
drop procedure if exists ui.[MenuModule.Merge];
drop procedure if exists ui.[Catalog.Merge];
drop type if exists ui.[MenuModule.TableType];
drop type if exists ui.[Catalog.TableType];
go
-------------------------------------------------
create type ui.[MenuModule.TableType] as table
(
	Id bigint,
	Parent bigint,
	[Name] nvarchar(255),
	[Url] nvarchar(255),
	Icon nvarchar(255),
	[Model] nvarchar(255),
	[Order] int,
	[Description] nvarchar(255),
	[Help] nvarchar(255),
	Module nvarchar(16),
	ClassName nvarchar(255)
);
go
-------------------------------------------------
create type ui.[Catalog.TableType] as table (
	Id int, 
	Menu nvarchar(16), 
	[Name] nvarchar(255), 
	[Order] int, 
	Category nvarchar(32), 
	[Memo] nvarchar(255), 
	[Url] nvarchar(255), 
	Icon nvarchar(16)
);
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'ui' and TABLE_NAME=N'Catalog')
create table ui.[Catalog]
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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'ui' and SEQUENCE_NAME=N'SQ_Menu')
	create sequence ui.SQ_Menu as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'ui' and TABLE_NAME=N'Menu')
create table ui.Menu
(
	Id	bigint not null constraint PK_Menu primary key
		constraint DF_Menu_PK default(next value for ui.SQ_Menu),
	Parent bigint null
		constraint FK_Menu_Parent_Menu foreign key references ui.Menu(Id),
	[Key] nchar(4) null,
	[Name] nvarchar(255) null,
	[Url] nvarchar(255) null,
	Icon nvarchar(255) null,
	Model nvarchar(255) null,
	Help nvarchar(255) null,
	[Order] int not null constraint DF_Menu_Order default(0),
	[Description] nvarchar(255) null,
	[Params] nvarchar(255) null,
	[Feature] nchar(4) null,
	[Feature2] nvarchar(255) null,
	[ClassName] nvarchar(255) null	
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
set nocount on;
if not exists(select * from a2sys.SysParams where [Name] = N'AppTitle')
	insert into a2sys.SysParams ([Name], StringValue) values (N'AppTitle', N'Нова Ера');
else
	update a2sys.SysParams set StringValue = N'Нова Ера' where [Name] = N'AppTitle';
go
------------------------------------------------
create procedure ui.[MenuModule.Merge]
@Menu ui.[MenuModule.TableType] readonly,
@Start bigint,
@End bigint
as
begin
	with T as (
		select * from ui.Menu where Id >=@Start and Id <= @End
	)
	merge T as t
	using @Menu as s
	on t.Id = s.Id 
	when matched then
		update set
			t.Id = s.Id,
			t.Parent = s.Parent,
			t.[Name] = s.[Name],
			t.[Url] = s.[Url],
			t.[Icon] = s.Icon,
			t.[Order] = s.[Order],
			t.Model = s.Model,
			t.[Description] = s.[Description],
			t.Help = s.Help,
			t.ClassName = s.ClassName
	when not matched by target then
		insert(Id, Parent, [Name], [Url], Icon, [Order], Model, [Description], Help, ClassName) values 
		(Id, Parent, [Name], [Url], Icon, [Order], Model, [Description], Help, ClassName)
	when not matched by source and t.Id >= @Start and t.Id < @End then 
		delete;
end
go
------------------------------------------------
create or alter procedure ui.[Catalog.Merge]
@Catalog ui.[Catalog.TableType] readonly,
@Start bigint,
@End bigint
as
begin
	set nocount on;
	with T as (
		select * from ui.[Catalog] where Id >=@Start and Id <= @End
	)
	merge T as t
	using @Catalog as s
	on t.Id = s.Id 
	when matched then
		update set
			t.Menu = s.Menu,
			t.[Name] = s.[Name],
			t.[Url] = s.[Url],
			t.[Icon] = s.Icon,
			t.[Order] = s.[Order],
			t.Category = s.Category,
			t.[Memo] = s.[Memo]
	when not matched by target then
		insert(Id, [Menu], [Name], [Url], Icon, [Order], Category, Memo) values 
		(Id, [Menu], [Name], [Url], Icon, [Order], Category, Memo)
	when not matched by source and t.Id >= @Start and t.Id < @End then 
		delete;
end
go
------------------------------------------------
create or alter procedure ui.[Menu.Simple.User.Load]
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
			from ui.Menu m0
			where m0.Id = @Root
		union all
		select m1.Id, m1.Parent, RT.[Level]+1
			from RT inner join ui.Menu m1 on m1.Parent = RT.Id
	)
	select [Menu!TMenu!Tree] = null, [Id!!Id]=RT.Id, [!TMenu.Menu!ParentId]=RT.ParentId,
		[Menu!TMenu!Array] = null,
		m.Name, m.Url, m.Icon, m.[Description], m.Help, m.Params, m.ClassName
	from RT 
		inner join ui.Menu m on RT.Id=m.Id
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

	declare @menu ui.[MenuModule.TableType];

	insert into @menu(Id, Parent, [Order], [Name], [Url], Icon, ClassName) 
	values
		(1,  null,  0, N'Main',         null,         null, null),
		(2,  null,  0, N'Start',         null,         null, null),
		(3,  null,  0, N'Init',      null,         null, null),

		(71,    2,  1, N'@[Welcome]',     N'appstart',   N'success-outline', null),
		(72,    3,  1, N'@[AppInit]',     N'appinit',    N'arrow-up', null),

		(10,    1,  10, N'@[Dashboard]',     N'dashboard',   N'dashboard-outline', null),
		(14,    1,  11, N'@[Tasks]',         N'task',        N'task-complete', null),
		(15,    1,  12, N'@[Crm]',           N'crm',         N'share', null),
		(20,    1,  20, N'@[Sales]',         N'sales',       N'shopping', N'border-top'),
		(21,    1,  21, N'@[Purchases]',     N'purchase',    N'cart', null),
		(50,    1,  50, N'@[Accounting]',    N'accounting',  N'calc', null),
		--(14,    1,  16, N'@[Manufacturing]', N'$manufacturing',  N'wrench', null),
		--(16,    1,  17, N'@[Payroll]',       N'payroll',  N'calc', null),
		--(17,    1,  18, N'@[Tax]',           N'tax',  N'calc', null),
		(88,    1,  880, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
		(90,    1,  900, N'@[Profile]',        N'profile',   N'user', null),
		-- TASKS
		(1401,  14, 10, N'@[Board]',          N'kanban',    N'dashboard-outline', null),
		-- CRM
		(1101,  15, 11, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1102,  15, 12, N'@[Leads]',          N'lead',      N'users', N'border-top'),
		(1103,  15, 13, N'@[Contacts]',       N'contact',   N'address-card', null),
		(110,   15, 14, N'@[Catalogs]',       null,  null, null),
		(1105, 110, 15, N'@[Agents]',         N'agent',     N'users', null),
		(1106, 110, 16, N'@[CatalogOther]',   N'catalog',   N'list', null),
		-- Sales
		(1201,   20, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(120,    20, 11, N'@[Documents]',      null,  null, null),
		(1202,   120, 2, N'@[Orders]',         N'order',     N'task-complete', null),
		(1203,   120, 3, N'@[Sales]',          N'sales',     N'shopping', null),
		(1204,   120, 4, N'@[Payment]',        N'payment',   N'currency-uah', null),
		(121,    20, 12, N'@[PriceLists]', null, null, null),
		(1210,	 121, 11, N'@[Prices]',         N'price',     N'tag-outline', null),
		(122,    20, 12, N'@[Catalogs]',      null,  null, null),
		(1220,   122, 30, N'@[Customers]',      N'agent',     N'users', null),
		(1221,   122, 31, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1222,   122, 32, N'@[Projects]',       N'project',   N'log', null),
		(1223,   122, 33, N'@[Items]',          N'item',      N'package-outline', N'line-top'),
		(1224,   122, 34, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1230,   20, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1231,   20, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Purchase
		(1301,   21, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(130,    21, 11, N'@[Documents]',      null,  null, null),
		(1302,  130, 10, N'@[Purchases]',      N'purchase',  N'cart', null),
		(1303,  130, 11, N'@[Warehouse]',      N'stock',     N'warehouse', null),
		(1304,  130, 12, N'@[Payment]',        N'payment',   N'currency-uah', null),
		--(1310,   14, 20, N'@[Planning]',       N'plan',      N'calendar', N'border-top'),
		--(131,    14, 12, N'@[Prices]', null, null, null),
		--(1311,  131, 10, N'@[PriceDoc]',       N'pricedoc',  N'file', null),
		--(1312,  131, 11, N'@[Prices]',         N'price',     N'tag-outline', null),
		(133,    21, 14, N'@[Catalogs]',  null, null, null),
		(1320,  133, 10, N'@[Suppliers]',      N'agent',     N'users', null),
		(1321,  133, 11, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1322,  133, 12, N'@[Items]',          N'item',      N'package-outline', N'line-top'),
		(1323,  133, 13, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1330,   21, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1331,   21, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Accounting
		(1501,   50, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(150,    50, 11, N'@[Documents]',      null, null, null),
		(1502,  150, 10, N'@[Bank]',           N'bank',   N'bank',  null),
		(1503,  150, 11, N'@[CashAccount]',    N'cash',   N'currency-uah',  null),
		(1504,   50, 12, N'@[AccountPlans]',   N'plan',      N'account',  N'border-top'),
		(153,    50, 15, N'@[Catalogs]',  null, null, null),
		(1505,  153, 10, N'@[BankAccounts]',   N'bankacc',   N'bank', null),
		(1506,	153, 11, N'@[CashAccounts]',   N'cashacc',   N'currency-uah', null),
		(1507,  153, 12, N'@[Agents]',         N'agent',     N'users', null),
		(1508,  153, 13, N'@[Persons]',        N'person',    N'user-role', null),
		(1509,  153, 14, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1510,  153, 15, N'@[Projects]',       N'project',   N'log', null),
		(1511,  153, 16, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1512,   50, 20, N'@[Journal]',        N'journal',   N'file-content',  N'border-top'),
		(1530,   50, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1531,   50, 41, N'@[Service]',        N'service',   N'gear-outline', null),

		-- Settings
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
		(884,   88, 14, N'@[Administration]', null, null, N'line-top'),
		(8841, 884, 20, N'@[Users]',        N'user',    N'user',  null),
		(885,   88, 15, N'@[Integrations]', 'integration',N'queue', N'border-top'),
		(8850,  88, 30, N'Розробка (debug)',N'develop',   N'switch', N'border-top'),
		(8851,  88, 99, N'Test',            N'test',      N'file', null),
		(8852,  88, 100, N'Test Group',     N'testgroup',      N'file', null),
		-- Profile
		(9001,  90, 10, N'@[Defaults]',    N'default',   N'list', null),
		(9002,  90, 20, N'@[License]',     N'license',   N'policy', null);

	exec ui.[MenuModule.Merge] @menu, 1, 9999;
end
go
-------------------------------------------------
-- Catalog
begin
	set nocount on;
	declare @cat ui.[Catalog.TableType];

	insert into @cat (Id, Menu, [Order], [Category], [Name], [Url], Icon, Memo) values

	(100, N'Sales', 10, N'@[Items]', N'@[Units]',         N'/catalog/unit/index',       N'list',  N''),
	(102, N'Sales', 11, N'@[Items]', N'@[Grouping.Item]', N'/catalog/itemgroup/index',  N'list',  N''),
	(103, N'Sales', 12, N'@[Items]', N'@[Variant.Setup]', N'/catalog/itemoption/index', N'list',  N''),
	--(102, N'Sales', 12, N'@[Items]', N'@[Brands]',   N'/catalog/brand/index', N'list',  N''),
	(105, N'Sales', 11, N'@[Prices]', N'@[PriceKinds]',   N'/catalog/pricekind/index', N'list',  N''),

	(200, N'Purchase',   10, N'@[Items]',  N'@[Units]',        N'/catalog/unit/index', N'list',  N''),
	(201, N'Purchase',   11, N'@[Items]',  N'@[Grouping.Item]', N'/catalog/itemgroup/index', N'list',  N''),
	(202, N'Purchase',   12, N'@[Prices]', N'@[PriceKinds]',   N'/catalog/pricekind/index', N'list',  N''),

	-- accounting
	(300, N'Accounting',  10, N'@[Accounting]', N'@[Banks]', N'/catalog/bank/index', N'list',  N''),
	(301, N'Accounting',  11, N'@[Accounting]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N''),
	(305, N'Accounting',  12, N'@[Items]',     N'@[Units]',      N'/catalog/unit/index', N'list',  N''),
	(306, N'Accounting',  13, N'@[Prices]',    N'@[PriceKinds]', N'/catalog/pricekind/index', N'list',  N''),

	-- crm
	(400, N'Crm',         10, N'@[Leads]',    N'@[LeadStages]',        N'/catalog/crm/leadstage/index', N'list',  N''),

	-- settings
	(900, N'Settings',  01, N'@[General]',   N'@[Countries]',   N'/catalog/country/index', N'list',  N''),
	(901, N'Settings',  02, N'@[General]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N''),
	(902, N'Settings',  03, N'@[General]',   N'@[RespCenters]', N'/catalog/respcenter/index', N'list',  N''),
	(910, N'Settings',  10, N'@[Accounts]',  N'@[ItemRoles]',   N'/catalog/itemrole/index', N'list',  N''),
	(911, N'Settings',  11, N'@[Accounts]',  N'@[AccKinds]',    N'/catalog/acckind/index', N'list',  N''),
	(915, N'Settings',  12, N'@[Documents]', N'@[Autonums]',    N'/catalog/autonum/index', N'list',  N''),
	(916, N'Settings',  13, N'@[Documents]', N'@[DocStates]',   N'/catalog/docstate/index', N'list',  N''),
	(920, N'Settings',  21, N'@[Accounting]', N'@[Banks]',         N'/catalog/bank/index', N'list',  N''),
	(922, N'Settings',  23, N'@[Accounting]', N'@[CostItems]',     N'/catalog/costitem/index', N'list',  N''),
	(923, N'Settings',  24, N'@[Accounting]', N'@[CashFlowItems]', N'/catalog/cashflowitem/index', N'list',  N''),
	(924, N'Settings',  25, N'@[Accounting]', N'@[Taxes]',         N'/catalog/taxes/index', N'list',  N''),
	(931, N'Settings',  31, N'@[Items]',  N'@[Grouping.Item]',     N'/catalog/itemgroup/index', N'list',  N''),
	(932, N'Settings',  32, N'@[Items]',  N'@[Categories]',        N'/catalog/itemcategory/index', N'list',  N''),
	(933, N'Settings',  33, N'@[Items]',  N'@[Units]',             N'/catalog/unit/index', N'list',  N''),
	(934, N'Settings',  34, N'@[Items]',  N'@[Brands]',            N'/catalog/brand/index', N'list',  N''),
	(945, N'Settings',  35, N'@[Items]',  N'@[Vendors]',           N'/catalog/vendor/index', N'list',  N''),
	(940, N'Settings',  40, N'@[Prices]', N'@[PriceKinds]',        N'/catalog/pricekind/index', N'list',  N''),
	(950, N'Settings',  50, N'@[Crm]',    N'@[LeadStages]',        N'/catalog/crm/leadstage/index', N'list',  N'');

	exec ui.[Catalog.Merge] @cat, 100, 999;
end
go
-------------------------------------------------
create or alter procedure ui.[Catalog.Other.Index]
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
	from ui.[Catalog]
	where Menu = @Menu order by [Order];
end
go
-------------------------------------------------
-- Integrations
begin
	set nocount on;
	declare @int table(Id int, [Key] nvarchar(16), [Name] nvarchar(255), [Order] int, 
		Category nvarchar(32), [Memo] nvarchar(255), [SetupUrl] nvarchar(255), DocumentUrl nvarchar(255),
		Icon nvarchar(16), Logo nvarchar(255));
	insert into @int (Id, [Key], [Order], [Category], [Name], [SetupUrl], DocumentUrl, Icon, Logo, Memo) values
	-- delivery services
	(1000, N'Delivery', 1000, N'@[Int.Delivery]', N'Нова пошта',    
		N'/integration/delivery/novaposhta/setup', N'/integration/delivery/novaposhta/document', 
		N'list',  N'/img/logo/np_logo.png', N'');

	merge app.[IntegrationSources] as t
	using @int as s on t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Key] = s.[Key],
		t.[Order] = s.[Order],
		t.Memo = s.Memo,
		t.[SetupUrl] = s.[SetupUrl],
		t.DocumentUrl = s.DocumentUrl,
		t.Logo = s.Logo,
		t.Icon = s.Icon
	when not matched by target then insert
		(Id,  [Key], [Name], [Order], Memo, [SetupUrl], DocumentUrl, Icon, Logo) values
		(s.Id, [Key], s.[Name], [Order], Memo, [SetupUrl], DocumentUrl, Icon, Logo)
	when not matched by source then delete;
end
go
