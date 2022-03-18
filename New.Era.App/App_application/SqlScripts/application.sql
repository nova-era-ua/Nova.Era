/*
version: 10.1.1001
generated: 18.03.2022 07:50:07
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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Vendors')
	create sequence cat.SQ_Vendors as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Vendors')
create table cat.Vendors
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Vendors_PK default(next value for cat.SQ_Vendors),
	Void bit not null 
		constraint DF_Vendors_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Vendors primary key (TenantId, Id)
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
	Unit bigint, /* base, references cat.Units */
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	Vendor bigint, -- references cat.Vendors
	Brand bigint, -- references cat.Brands
		constraint PK_Items primary key (TenantId, Id),
		constraint FK_Items_Unit_Units foreign key (TenantId, Unit) references cat.Units(TenantId, Id),
		constraint FK_Items_Vendor_Vendors foreign key (TenantId, Vendor) references cat.Vendors(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_ItemTree')
	create sequence cat.SQ_ItemTree as bigint start with 100 increment by 1;
go
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'ItemTree')
create table cat.ItemTree
(
	TenantId int not null,
	Id bigint not null
		constraint DF_ItemTree_PK default(next value for cat.SQ_ItemTree),
	[Root] bigint not null,
	Parent bigint not null,
	Void bit not null
		constraint DF_ItemTree_Void default(0),
	[Name] nvarchar(255),
		constraint PK_ItemTree primary key (TenantId, Id),
		constraint FK_ItemTree_Root_ItemTree foreign key (TenantId, [Root]) references cat.ItemTree(TenantId, Id),
		constraint FK_ItemTree_Parent_ItemTree foreign key (TenantId, Parent) references cat.ItemTree(TenantId, Id)
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
@CompanyId bigint = 0,
@UserId bigint,
@HideSearch bit = 0,
@TreeId bigint = 1
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with T(Id, [Name], Icon, HasChildren, IsSpec)
	as (
		select Id = cast(-1 as bigint), [Name] = N'@[SearchResult]', Icon='search',
			HasChildren = cast(0 as bit), IsSpec=1
		where @HideSearch = 0
		union all
		select Id, [Name], Icon = N'folder-outline',
			HasChildren= case when exists(select 1 from cat.ItemTree it where it.Void = 0 and it.Parent = t.Id) then 1 else 0 end,
			IsSpec = 0
		from cat.ItemTree t
			where t.Void = 0 and t.Parent = @TreeId
	)
	select [Folders!TFolder!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon,
		/*nested folders - lazy*/
		[SubItems!TFolder!Items] = null, 
		/* marker: subfolders exist */
		[HasSubItems!!HasChildren] = HasChildren,
		/*nested items (not folders!) */
		[Children!TItem!LazyArray] = null
	from T
	order by [IsSpec], [Name];
end
go
------------------------------------------------
drop procedure if exists cat.[Item.Folder.Metadata];
drop procedure if exists cat.[Item.Folder.Update];
drop procedure if exists cat.[Item.Item.Metadata];
drop procedure if exists cat.[Item.Item.Update];
drop type if exists cat.[Item.Folder.TableType];
go
------------------------------------------------
create type cat.[Item.Folder.TableType]
as table(
	Id bigint null,
	ParentFolder bigint,
	[Name] nvarchar(255)
)
go
-------------------------------------------------
create or alter procedure cat.[Item.Folder.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null,
@Parent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Folder!TFolder!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		ParentFolder = Parent
	from cat.ItemTree where Id = @Id;

	select [ParentFolder!TParentFolder!Object] = null,  [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree 
	where Id=@Parent;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Folder.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Folder [Item.Folder.TableType];
	select [Folder!Folder!Metadata] = null, * from @Folder;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Folder.Update]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Folder [Item.Folder.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @xml nvarchar(max);
	set @xml = (select * from @Folder for xml auto);
	throw 60000, @xml, 0;

	declare @output table(op sysname, id bigint);
	declare @Root bigint;
	set @Root = 1;

	merge cat.ItemTree as t
	using @Folder as s
	on (t.Id = s.Id)
	when matched then
		update set 
			t.[Name] = s.[Name]
	when not matched by target then 
		insert (TenantId, [Root], Parent, [Name])
		values (@TenantId, @Root, s.ParentFolder, s.[Name])
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	select [Folder!TFolder!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon=N'folder-outline',
		ParentFolder = Parent
	from cat.ItemTree 
	where Id=@RetId;
end
go

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

