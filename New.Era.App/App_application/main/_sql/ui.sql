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
@TenantId int = 0,
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

	-- companies
	exec a2security.[User.Companies] @UserId = @UserId;

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
		(10,    1,  10, N'@[Dashboard]',      N'dashboard',   N'dashboard-outline', null),
		(11,    1,  11, N'@[SalesMarketing]', N'sales',       N'list', null),
		(12,    1,  12, N'@[StockPurchases]', N'purchase',    N'cart', null),
		(13,    1,  13, N'@[Accounting]',     N'accounting',  N'calc', null),
		(30,    1,  30, N'@[Catalogs]',       N'catalog',   N'list', N'border-top'),
		(90,    1,  90, N'@[Settings]',       N'settings',  N'gear-outline', null),
		(111,   11, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(121,   12, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(131,   13, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(132,   13, 10, N'@[AccountsPlan]',   N'plan',     N'account', null),
		(301,   30, 10, N'@[Agents]',        N'agent',     N'users', null),
		(302,   30, 20, N'@[Items]',         N'item',      N'package-outline', null),
		(309,   30, 90, N'@[Other]',         N'other',     N'items', N'border-top'),
		(901,   90, 10, N'@[Operations]',    N'operation', N'list', null);

	exec a2ui.[MenuModule.Merge] @menu, 1, 999;
end
go
------------------------------------------------
create or alter procedure a2ui.[Catalog.Other.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Catalog!TCatalog!Array] = null
end
go