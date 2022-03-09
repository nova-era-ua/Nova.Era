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

	insert into @menu(Id, Parent, [Order], [Name], [Url], Icon) 
	values
		(1,  null,  0, N'Main',         null,         null),
		(10,    1, 10, N'@[Dashboard]', N'dashboard', N'dashboard-outline');

	exec a2ui.[MenuModule.Merge] @menu, 1, 900;
end
go
