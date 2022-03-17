/*
version: 10.1.1001
generated: 17.03.2022 15:54:22
*/


/* SqlScripts/application.sql */

/*
main structure
*/
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'cat')
	exec sp_executesql N'create schema cat';
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Units')
	create sequence cat.SQ_Units as bigint start with 100 increment by 1;
go
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Units')
create table cat.Units
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Units_PK default(next value for cat.SQ_Units),
	Void bit not null 
		constraint DF_Units_Void default(0),
	Short nvarchar(8),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Units primary key (TenantId, Id),
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Items')
	create sequence cat.SQ_Items as bigint start with 100 increment by 1;
go
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items')
create table cat.Items
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Items_PK default(next value for cat.SQ_Items),
	Void bit not null 
		constraint DF_Items_Void default(0),
	Article nvarchar(16),
	Unit bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Items primary key (TenantId, Id),
		constraint FK_Items_Unit_Units foreign key (TenantId, Unit) references cat.Units(TenantId, Id),
);
go

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
		(10,    1, 10, N'@[Dashboard]', N'dashboard', N'dashboard-outline'),
		(30,    1, 10, N'@[Catalogs]',  N'catalog',   N'list'),
		(301,   30, 10, N'@[Agents]',   N'agent',     N'users'),
		(302,   30, 20, N'@[Items]',    N'item',      N'package-outline');

	exec a2ui.[MenuModule.Merge] @menu, 1, 900;
end
go

/* Item */
-------------------------------------------------
create or alter procedure cat.[Item.Index]
@TenantId int = 1,
@UserId bigint,
@CompanyId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Items!TItem!Array] = null, [Id!!Id] = Id
	from cat.Items
	where TenantId = @TenantId;
end
go
-------------------------------------------------

/*
admin
*/
------------------------------------------------
if not exists(select * from a2security.Users where Id <> 0)
begin
	set nocount on;
	set transaction isolation level read committed;

	insert into a2security.Users(Id, UserName, SecurityStamp, PasswordHash, PersonName, EmailConfirmed)
	values (99, N'admin@admin.com', N'c9bb451a-9d2b-4b26-9499-2d7d408ce54e', N'AJcfzvC7DCiRrfPmbVoigR7J8fHoK/xdtcWwahHDYJfKSKSWwX5pu9ChtxmE7Rs4Vg==',
		N'System administrator', 1);
	insert into a2security.UserGroups(UserId, GroupId) values (99, 77), (99, 1); /*predefined values*/
end
go
------------------------------------------------
if not exists(select * from a2security.Companies)
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	begin tran;
	insert into a2security.Companies ([Name]) 
	output inserted.Id into @rtable(id)
	values (N'Моє підприємство');
	
	declare @comp bigint;
	select @comp = id from @rtable;

	insert into a2security.UserCompanies([User], Company, [Enabled])
	values (99, @comp, 1);

	update a2security.Users set Company = @comp where Id=99;
	commit tran;
end
go

