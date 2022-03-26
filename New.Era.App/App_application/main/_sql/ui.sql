/*
user interface
*/
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
		(11,    1,  11, N'@[Crm]',           N'crm',         N'share', null),
		(12,    1,  12, N'@[Sales]',         N'sales',       N'shopping', null),
		(13,    1,  13, N'@[Purchases]',     N'purchase',    N'cart', null),
		(14,    1,  14, N'@[Manufacturing]', N'manufacturing',  N'wrench', null),
		(15,    1,  15, N'@[Accounting]',    N'accounting',  N'calc', null),
		(16,    1,  16, N'@[Payroll]',       N'payroll',  N'calc', null),
		(17,    1,  17, N'@[Tax]',           N'tax',  N'calc', null),
		(30,    1,  30, N'@[Catalogs]',       N'catalog',   N'list',         N'border-top'),
		(90,    1,  90, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
		-- CRM
		(1101,  11, 11, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1102,  11, 12, N'@[Leads]',          N'lead',      N'users', N'border-top'),
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
		(1310,   13, 20, N'@[Planning]',       N'plan',      N'calendar', N'border-top'),
		(1311,   13, 21, N'@[Prices]',         N'price',     N'chart-column', null),
		(1320,   13, 30, N'@[Suppliers]',      N'agent',     N'users', N'border-top'),
		(1321,   13, 31, N'@[Items]',          N'item',      N'package-outline', null),
		(1322,   13, 32, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1330,   13, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1331,   13, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Accounting
		(152,   15, 10, N'@[AccountsPlan]',   N'plan',     N'account',    N'border-top'),
		(153,   15, 12, N'@[Journal]',        N'journal',  N'file-content',  null),
		(301,   30, 10, N'@[Agents]',        N'agent',     N'users',   null),
		(302,   30, 20, N'@[Items]',         N'item',      N'package-outline', null),
		(309,   30, 90, N'@[Other]',         N'other',       N'items',   N'border-top'),

		-- Settings
		(9010,  90, 10, N'@[Companies]', N'company', N'company', null),
		(901,   90, 14, N'@[AccountsPlan]',  N'accountplan', N'account',      N'border-top'),
		(902,   90, 14, N'@[Operations]',    N'operation',   N'file-content', null);

	exec a2ui.[MenuModule.Merge] @menu, 1, 9999;
end
go
------------------------------------------------
create or alter procedure a2ui.[Catalog.Other.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Catalog!TCatalog!Array] = null
end
go
