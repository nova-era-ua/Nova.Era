/*
version: 10.1.1005
generated: 26.03.2022 06:34:37
*/


/* SqlScripts/application.sql */

/*
main structure
*/
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'cat')
	exec sp_executesql N'create schema cat';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'doc')
	exec sp_executesql N'create schema doc';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'acc')
	exec sp_executesql N'create schema acc';
go
------------------------------------------------
grant execute on schema::cat to public;
grant execute on schema::doc to public;
grant execute on schema::acc to public;
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
	Article nvarchar(32),
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
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'ItemTreeItems')
create table cat.ItemTreeItems
(
	TenantId int not null,
	Parent bigint not null,
	Item bigint not null,
		constraint PK_ItemTreeItems primary key (TenantId, Parent, Item),
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Agents')
	create sequence cat.SQ_Agents as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Agents')
create table cat.Agents
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Agents_PK default(next value for cat.SQ_Agents),
	Void bit not null 
		constraint DF_Agents_Void default(0),
	Kind nvarchar(16), /* Company, Agent */
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Agents primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Accounts')
	create sequence cat.SQ_Accounts as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'acc' and TABLE_NAME=N'Accounts')
create table acc.Accounts (
	TenantId int not null,
	Id bigint not null
		constraint DF_Accounts_PK default(next value for cat.SQ_Accounts),
	Void bit not null 
		constraint DF_Accounts_Void default(0),
	[Plan] bigint null,
	Parent bigint null,
	[Code] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Accounts primary key (TenantId, Id),
		constraint FK_Accounts_Parent_Accounts foreign key (TenantId, [Parent]) references acc.Accounts(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OperationGroups')
create table doc.OperationGroups
(
	TenantId int not null,
	Id nvarchar(16) not null,
	[Name] nvarchar(255),
	[Order] int,
	[Memo] nvarchar(255),
		constraint PK_OperationGroups primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'DocumentForms')
create table doc.DocumentForms
(
	TenantId int not null,
	Id nvarchar(16) not null,
	[Name] nvarchar(255),
	[Url] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_DocumentForms primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_Operations')
	create sequence doc.SQ_Operations as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations')
create table doc.Operations
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Operations_PK default(next value for doc.SQ_Operations),
	Void bit not null 
		constraint DF_Operations_Void default(0),
	[Group] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Agent] nchar(1),
	DocumentForm nvarchar(16),
	[WarehouseFrom] nchar(1),
	[WarehouseTo] nchar(1)
		constraint PK_Operations primary key (TenantId, Id),
		constraint FK_Operations_Group_OperationGroups foreign key (TenantId, [Group]) references doc.OperationGroups(TenantId, Id),
		constraint FK_Operations_DocumentForm_OperationGroups foreign key (TenantId, [DocumentForm]) references doc.DocumentForms(TenantId, Id),
);
go

------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_Documents')
	create sequence doc.SQ_Documents as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents')
create table doc.Documents
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Documents_PK default(next value for doc.SQ_Documents),
	Company bigint not null,
	[Date] datetime,
	Operation bigint not null,
	[Sum] money not null
		constraint DF_Documents_Sum default(0),
	Agent bigint,
	Memo nvarchar(255),
		constraint PK_Documents primary key (TenantId, Id),
		constraint FK_Documents_Company_Agents foreign key (TenantId, Company) references cat.Agents(TenantId, Id),
		constraint FK_Documents_Operation_Operations foreign key (TenantId, [Operation]) references doc.Operations(TenantId, Id),
		constraint FK_Documents_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id)
);
go

/*
drop table doc.Operations
drop table doc.OperationGroups
drop table doc.Documents
drop table cat.Agents
*/

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
create or alter procedure a2ui.[Menu.Companies]
@TenantId int = 0,
@UserId bigint = null
as
begin
	-- all companies for the current user
	select [Companies!TCompany!Array] = null, c.Id, c.[Name], 
		[Current] = cast(1 as bit)
	from cat.Agents c where TenantId = @TenantId and Void = 0 and c.Kind = N'Company';
end
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

	-- companies
	exec a2ui.[Menu.Companies] @TenantId = @TenantId, @UserId = @UserId;

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
		(18,    1,  18, N'@[MyCompany]',     N'mycompany', N'company', N'border-top'),
		(30,    1,  30, N'@[Catalogs]',       N'catalog',   N'list',         N'border-top'),
		(90,    1,  90, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
		-- CRM
		(1101,  11, 11, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1102,  11, 12, N'@[Leads]',          N'lead',      N'users', N'border-top'),
		-- Sales
		(1201,   12, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1202,   12, 12, N'@[Sales]',          N'sales', N'shopping', N'border-top'),
		(1204,   12, 14, N'@[Payment]',        N'payment',   N'currency-uah', null),
		(1220,   12, 30, N'@[Customers]',      N'agent',     N'users', N'border-top'),
		(1221,   12, 31, N'@[Items]',          N'item',      N'package-outline', null),
		(1222,   12, 32, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1230,   12, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1231,   12, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Purchase
		(1301,   13, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1302,   13, 11, N'@[Purchases]',      N'purchase',  N'cart', N'border-top'),
		(1303,   13, 12, N'@[Warehouse]',      N'warehouse', N'warehouse', null),
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
		(901,   90, 10, N'@[AccountsPlan]',  N'accountplan', N'account',      null),
		(902,   90, 11, N'@[Operations]',    N'operation',   N'file-content', null);

	exec a2ui.[MenuModule.Merge] @menu, 1, 9999;
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

/* Item */
-------------------------------------------------
create or alter procedure cat.[Item.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@HideSearch bit = 0,
@HieId bigint = 1
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
			HasChildren= case when exists(
				select 1 from cat.ItemTree it where it.Void = 0 and it.Parent = t.Id and it.TenantId = @TenantId and t.TenantId = @TenantId
			) then 1 else 0 end,
			IsSpec = 0
		from cat.ItemTree t
			where t.TenantId = @TenantId and t.Void = 0 and t.Parent = @HieId
	)
	select [Folders!TFolder!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon,
		/*nested folders - lazy*/
		[SubItems!TFolder!Items] = null, 
		/* marker: subfolders exist */
		[HasSubItems!!HasChildren] = HasChildren,
		/*nested items (not folders!) */
		[Children!TItem!LazyArray] = null
	from T
	order by [IsSpec], [Id];

	select [Hierarchy!THierarchy!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where Id= @HieId;

	-- Children recordset declaration
	select [!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.FullName, i.Article, i.Memo,
		[ParentFolder.Id!TParentFolder!Id] = iti.Parent, [ParentFolder.Name!TParentFolder!Name] = it.[Name]
	from cat.Items i 
		inner join cat.ItemTreeItems iti on iti.Item = i.Id and iti.TenantId = i.TenantId
		inner join cat.ItemTree it on iti.Parent = it.Parent and iti.TenantId = it.TenantId
	where 0 <> 0;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Expand]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [SubItems!TFolder!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon = N'folder-outline',
		[SubItems!TFolder!Items] = null,
		[HasSubItems!!HasChildren] = case when exists(select 1 from cat.ItemTree c where c.Void=0 and c.Parent=a.Id) then 1 else 0 end,
		[Children!TItem!LazyArray] = null
	from cat.ItemTree a where Parent = @Id and Void=0;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Children]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Asc nvarchar(10), @Desc nvarchar(10), @RowCount int;
	declare @fr nvarchar(255);

	set @Asc = N'asc'; set @Desc = N'desc';
	set @Dir = lower(isnull(@Dir, @Asc));
	set @Order = lower(@Order);
	set @fr = N'%' + upper(@Fragment) + N'%';

	with T(Id, Parent, RowNumber)
	as (
		select Id, Parent,
			[RowNumber] = row_number() over (
				order by 
					case when @Order=N'id'   and @Dir=@Asc  then i.Id end asc,
					case when @Order=N'id'   and @Dir=@Desc then i.Id end desc,
					case when @Order=N'name' and @Dir=@Asc  then i.[Name] end asc,
					case when @Order=N'name' and @Dir=@Desc then i.[Name] end desc,
					case when @Order=N'article' and @Dir=@Asc  then i.Article end asc,
					case when @Order=N'article' and @Dir=@Desc then i.Article end desc,
					case when @Order=N'memo' and @Dir=@Asc  then i.Memo end asc,
					case when @Order=N'memo' and @Dir=@Desc then i.Memo end desc
			)
			from cat.Items i
			inner join cat.ItemTreeItems iti on i.TenantId = iti.TenantId and i.Id = iti.Item
		where i.Void = 0 and (
			i.TenantId = @TenantId and iti.TenantId = @TenantId and iti.Parent = @Id or
				(@Id = -1 and (upper([Name]) like @fr or upper(Memo) like @fr))
			)
	) select [Children!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], 
		i.FullName, i.Article, i.Memo, 
		[ParentFolder.Id!TParentFolder!Id] = T.Parent, [ParentFolder.Name!TParentFolder!Name] = t.[Name],
		[!!RowCount]  = (select count(1) from T)
	from T inner join cat.Items i on T.Id = i.Id and i.TenantId = @TenantId
		inner join cat.ItemTree t on T.Parent = t.Id and t.TenantId = @TenantId
	order by RowNumber offset (@Offset) rows fetch next (@PageSize) rows only;

	-- system data
	select [!$System!] = null,
		[!Children!PageSize] = @PageSize, 
		[!Children!SortOrder] = @Order, 
		[!Children!SortDir] = @Dir,
		[!Children!Offset] = @Offset,
		[!Children.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
drop procedure if exists cat.[Item.Folder.Metadata];
drop procedure if exists cat.[Item.Folder.Update];
drop procedure if exists cat.[Item.Item.Metadata];
drop procedure if exists cat.[Item.Item.Update];
drop type if exists cat.[Item.Folder.TableType];
drop type if exists cat.[Item.Item.TableType];
go
------------------------------------------------
create type cat.[Item.Folder.TableType]
as table(
	Id bigint null,
	ParentFolder bigint,
	[Name] nvarchar(255)
)
go
------------------------------------------------
create type cat.[Item.Item.TableType]
as table(
	Id bigint null,
	ParentFolder bigint,
	[Name] nvarchar(255),
	Article nvarchar(32),
	FullName nvarchar(255),
	[Memo] nvarchar(255)
);
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

	select [Folder!TFolder!Object] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name],
		[ParentFolder.Id!TParentFolder!Id] = t.Parent, [ParentFolder.Name!TParentFolder!Name] = p.[Name]
	from cat.ItemTree t
		inner join cat.ItemTree p on t.TenantId = p.TenantId and t.Parent = p.Id
	where t.TenantId=@TenantId and t.Id = @Id and t.Void = 0;

	select [ParentFolder!TParentFolder!Object] = null,  [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree 
	where Id=@Parent and TenantId = @TenantId;
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
------------------------------------------------
create or alter procedure cat.[Item.Item.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null,
@Parent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	if @Parent is null
		select @Parent = Parent from cat.ItemTreeItems where Item =@Id;
	select [Item!TItem!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.FullName, i.Article, i.Memo,
		[ParentFolder.Id!TParentFolder!Id] = iti.Parent, [ParentFolder.Name!TParentFolder!Name] = t.[Name]
	from cat.Items i 
		inner join cat.ItemTreeItems iti on i.Id = iti.Item and i.TenantId = iti.TenantId
		inner join cat.ItemTree t on iti.Parent = t.Id and iti.TenantId = t.TenantId
	where i.TenantId = @TenantId and iti.TenantId=@TenantId and t.TenantId = @TenantId 
		and i.Id=@Id and i.Void = 0;
	
	select [ParentFolder!TParentFolder!Object] = null,  [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree t
	where Id = @Parent and TenantId = @TenantId;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Item.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Item cat.[Item.Item.TableType];
	select [Item!Item!Metadata] = null, * from @Item;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Item.Update]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Item cat.[Item.Item.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Item for xml auto);
	throw 60000, @xml, 0;
	*/
	declare @output table(op sysname, id bigint);

	begin tran;
	merge cat.Items as t
	using @Item as s
	on (t.Id = s.Id and t.TenantId = @TenantId)
	when matched then
		update set 
			t.[Name] = s.[Name],
			t.FullName = s.FullName,
			t.[Article] = s.[Article],
			t.Memo = s.Memo
	when not matched by target then 
		insert (TenantId, [Name], FullName, [Article], Memo)
		values (@TenantId, s.[Name], FullName, Article, Memo)
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	merge cat.ItemTreeItems  as t
	using (select Item = @RetId, ParentFolder from @Item) as s
	on (t.Item = s.Item and t.Parent = s.ParentFolder and t.TenantId = @TenantId)
	when not matched by target then insert (TenantId, Parent, Item)
	values (@TenantId, s.ParentFolder, s.Item)
	when not matched by source and t.TenantId = @TenantId and t.Item = @RetId then delete;

	commit tran;

	exec cat.[Item.Item.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, 
		@UserId = @UserId, @Id = @RetId;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Folder.GetPath]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint,
@Root bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with T(Id, Parent, [Level]) as (
		select cast(null as bigint), @Id, 0
		union all
		select t.Id, t.Parent, [Level] + 1 
			from cat.ItemTree t inner join T on t.Id = T.Parent and t.TenantId = @TenantId
		where t.Id <> @Root
	)
	select [Result!TResult!Array] = null, [Id] = Id from T where Id is not null order by [Level] desc;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Item.FindIndex]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint,
@Parent bigint,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc'
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Asc nvarchar(10), @Desc nvarchar(10), @RowCount int;

	set @Asc = N'asc'; set @Desc = N'desc';
	set @Dir = lower(isnull(@Dir, @Asc));
	set @Order = lower(@Order);

	with T(Id, RowNumber)
	as (
		select Id, [RowNumber] = row_number() over (
				order by 
					case when @Order=N'id'   and @Dir=@Asc  then i.Id end asc,
					case when @Order=N'id'   and @Dir=@Desc then i.Id end desc,
					case when @Order=N'name' and @Dir=@Asc  then i.[Name] end asc,
					case when @Order=N'name' and @Dir=@Desc then i.[Name] end desc,
					case when @Order=N'article' and @Dir=@Asc  then i.Article end asc,
					case when @Order=N'article' and @Dir=@Desc then i.Article end desc,
					case when @Order=N'memo' and @Dir=@Asc  then i.Memo end asc,
					case when @Order=N'memo' and @Dir=@Desc then i.Memo end desc
			)
			from cat.Items i inner join cat.ItemTreeItems iti on
			i.TenantId = iti.TenantId and i.Id = iti.Item
			where iti.Parent = @Parent and iti.TenantId = @TenantId
	)
	select [Result!TResult!Object] = null, T.Id, RowNo = T.RowNumber - 1 /*row_number is 1-based*/
	from T
	where T.Id = @Id;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Folder.Delete]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	if exists(select 1 from cat.ItemTree where TenantId=@TenantId and Parent = @Id and Void = 0) or
	   exists(select 1 from cat.ItemTree where TenantId=@TenantId and Parent = @Id and Void = 0)
		throw 60000, N'UI:@[Error.Delete.Folder]', 0;
	update cat.ItemTree set Void=1 where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Item.Delete]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	-- TODO: check if there are any references
	begin tran
	update cat.Items set Void=1 where TenantId = @TenantId and Id = @Id;
	delete from cat.ItemTreeItems where
		TenantId = @TenantId and Item = @Id;
	commit tran;
end
go


/* Agent */
-------------------------------------------------
create or alter procedure cat.[Agent.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Agents!TAgent!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo]
	from cat.Agents a
	where TenantId = @TenantId and a.Kind = N'Agent';
end
go
-------------------------------------------------
create or alter procedure cat.[Agent.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Agent!TAgent!Object] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo]
	from cat.Agents a
	where TenantId = @TenantId and Id = @Id;
end
go
-------------------------------------------------
drop procedure if exists cat.[Agent.Metadata];
drop procedure if exists cat.[Agent.Update];
drop type if exists cat.[Agent.TableType];
go
-------------------------------------------------
create type cat.[Agent.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Agent.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Agent cat.[Agent.TableType];
	select [Agent!Agent!Metadata] = null, * from @Agent;
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Update]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Agent cat.[Agent.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Agents as t
	using @Agent as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[FullName] = s.[FullName]
	when not matched by target then insert
		(TenantId, Kind, [Name], FullName, Memo) values
		(@TenantId, N'Agent', s.[Name], s.FullName, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Agent.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, @UserId = @UserId, @Id = @id;
end
go

/* Accounting plan */

------------------------------------------------
create or alter procedure acc.[Account.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with T(Id, Parent, [Level])
	as (
		select a.Id, Parent, 0 from
			acc.Accounts a where TenantId=@TenantId and a.Parent is null and a.[Plan] is null
		union all 
		select a.Id, a.Parent, T.[Level] + 1 
		from acc.Accounts a
			inner join T on T.Id = a.Parent and a.TenantId = @TenantId
		where a.TenantId = @TenantId
	)
	select [Accounts!TAccount!Tree] = null, [Id!!Id] = T.Id, a.Code, a.[Name], a.[Plan],
		[Items!TAccount!Items] = null, [!TAccount.Items!ParentId] = T.Parent
	from T inner join acc.Accounts a on a.Id = T.Id and a.TenantId = @TenantId
	order by T.[Level], a.Code;
end
go
------------------------------------------------
create or alter procedure acc.[Account.Plan.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Account!TAccount!Object] = null, [Id!!Id] = Id, Code, [Name], [Memo], [Plan]
	from acc.Accounts where TenantId = @TenantId and Id=@Id and [Plan] is null and [Parent] is null;
end
go
------------------------------------------------
create or alter procedure acc.[Account.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null,
@Parent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Account!TAccount!Object] = null, [Id!!Id] = Id, Code, [Name], [Memo], [Plan], 
		ParentAccount = Parent
	from acc.Accounts where TenantId = @TenantId and Id=@Id;

	select [Params!TParam!Object] = null, ParentAccount = @Parent;
end
go
------------------------------------------------
drop procedure if exists acc.[Account.Plan.Metadata];
drop procedure if exists acc.[Account.Plan.Update];
drop procedure if exists acc.[Account.Metadata];
drop procedure if exists acc.[Account.Update];
drop type if exists acc.[Account.Plan.TableType];
drop type if exists acc.[Account.TableType];
go
------------------------------------------------
create type acc.[Account.Plan.TableType]
as table (
	Id bigint null,
	[Name] nvarchar(255),
	[Code] nvarchar(16),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create type acc.[Account.TableType]
as table (
	Id bigint null,
	[Name] nvarchar(255),
	[Code] nvarchar(16),
	[Memo] nvarchar(255),
	[ParentAccount] bigint
)
go
------------------------------------------------
create or alter procedure acc.[Account.Plan.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Account acc.[Account.Plan.TableType];
	select [Account!Account!Metadata] = null, * from @Account;
end
go
------------------------------------------------
create or alter procedure acc.[Account.Plan.Update]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Account acc.[Account.Plan.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	declare @rtable table(id bigint);
	declare @id bigint;
	merge acc.Accounts as t
	using @Account as s
	on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Code] = s.[Code],
		t.[Memo] = s.Memo
	when not matched by target then insert
		(TenantId, Code, [Name], [Memo]) values
		(@TenantId, s.Code, s.[Name], s.Memo)
	output inserted.Id into @rtable(id);
	select @id = id from @rtable;
	exec acc.[Account.Plan.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, 
		@UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure acc.[Account.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Account acc.[Account.TableType];
	select [Account!Account!Metadata] = null, * from @Account;
end
go
------------------------------------------------
create or alter procedure acc.[Account.Update]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Account acc.[Account.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	declare @rtable table(id bigint);
	declare @id bigint;
	declare @plan bigint;

	-- get plan id
	select @plan = isnull(p.[Plan], p.Id) from 
		@Account a inner join acc.Accounts p on a.ParentAccount = p.Id;

	merge acc.Accounts as t
	using @Account as s
	on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Code] = s.[Code],
		t.[Memo] = s.Memo
	when not matched by target then insert
		(TenantId, [Plan], Parent, Code, [Name], [Memo]) values
		(@TenantId, @plan, s.ParentAccount, s.Code, s.[Name], s.Memo)
	output inserted.Id into @rtable(id);
	select @id = id from @rtable;
	exec acc.[Account.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, 
		@UserId = @UserId, @Id = @id;
end
go

/* Operation */
-------------------------------------------------
create or alter procedure doc.[Operation.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Groups!TGroup!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[Children!TOperation!LazyArray] = null
	from doc.OperationGroups 
	where TenantId = @TenantId
	order by [Order];

	-- children declaration. same as Children proc
	select [!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo
	from doc.Operations where 1 <> 1;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Children]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id nvarchar(16)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Children!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo
	from doc.Operations o 
	where TenantId = @TenantId and [Group] = @Id
	order by Id;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null,
@Parent nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Operation!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Group],
		[Form.Id!TForm!Id] = df.Id, [Form.Name!TForm!Name] = df.[Name]
	from doc.Operations o 
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where o.TenantId = @TenantId and o.Id=@Id;


	select [Forms!TForm!Array] = null, [Id!!Id] = df.Id, [Name!!Name] = df.[Name]
	from doc.DocumentForms df
	where df.TenantId = @TenantId
	order by df.Id;

	select [Params!TParam!Object] = null, [ParentGroup] = @Parent;
end
go
-------------------------------------------------
drop procedure if exists doc.[Operation.Metadata];
drop procedure if exists doc.[Operation.Update];
drop type if exists doc.[Operation.TableType];
go
-------------------------------------------------
create type doc.[Operation.TableType]
as table(
	Id bigint null,
	[Group] nvarchar(16),
	[Form] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure doc.[Operation.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Operation doc.[Operation.TableType];
	select [Operation!Operation!Metadata] = null, * from @Operation;
end
go
------------------------------------------------
create or alter procedure doc.[Operation.Update]
@TenantId bigint = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Operation doc.[Operation.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	
	declare @rtable table(id bigint);
	declare @Id bigint;

	merge doc.Operations as t
	using @Operation as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[DocumentForm] = s.[Form]
	when not matched by target then insert
		(TenantId, [Group], [Name], DocumentForm, Memo) values
		(@TenantId, s.[Group], s.[Name], s.Form, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @Id = id from @rtable;
	exec doc.[Operation.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, @UserId = @UserId,
		@Id = @Id;
end
go

/* Document */
------------------------------------------------
create or alter procedure doc.[Document.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Group nvarchar(16)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name],
		o.[Memo],
		[Form.Id!TForm!Id] = df.Id, [Form.Url!TForm!] = df.[Url],
		[Documents!TDocument!LazyArray] = null
	from doc.Operations o
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where o.TenantId = @TenantId and o.[Group] = @Group
	order by o.Id;

	-- documents declaration
	select [!TDocument!Array] = null, [Id!!Id] = 0, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation
	from doc.Documents d 
	where d.TenantId = @TenantId and 0 <> 0;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Documents]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation
	from doc.Documents d 
	where d.TenantId = @TenantId and Operation = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form.Id!TForm!Id] = df.Id, [Form.Url!TForm!] = df.[Url]
	from doc.Operations o
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where o.Id = @Id;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null,
@Operation bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id

	select [Params!TParam!Object] = null,
		[Operation!TOperation!RefId] = @Operation;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form.Id!TForm!Id] = df.Id, [Form.Url!TForm!] = df.[Url]
	from doc.Operations o 
		left join doc.Documents d on d.TenantId = o.TenantId and d.Operation = o.Id
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where d.Id = @Id or o.Id = @Operation;

	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Documents d on d.TenantId = a.TenantId and d.Agent = a.Id
	where d.Id = @Id and d.TenantId = @Id;

end
go
------------------------------------------------
drop procedure if exists doc.[Document.Stock.Metadata];
drop procedure if exists doc.[Document.Stock.Update];
drop type if exists cat.[Document.Stock.TableType];
go
------------------------------------------------
create type cat.[Document.Stock.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Sum] money,
	Operation bigint,
	Agent bigint,
	Memo nvarchar(255)
)
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Document cat.[Document.Stock.TableType];
	select [Document!Document!Metadata] = null, * from @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Update]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Document cat.[Document.Stock.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge doc.Documents as t
	using @Document as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Date] = s.[Date],
		t.[Sum] = s.[Sum],
		t.Agent = s.Agent,
		t.Memo = s.Memo
	when not matched by target then insert
		(TenantId, Company, Operation, [Date], [Sum], Agent, Memo) values
		(@TenantId, @CompanyId, s.Operation, s.[Date], s.[Sum], s.Agent, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	exec doc.[Document.Stock.Load] @TenantId = @TenantId, @CompanyId=@CompanyId, 
	@UserId = @UserId, @Id = @id;
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

/*
initial data
*/

------------------------------------------------
if not exists(select * from cat.Agents where Kind=N'Company')
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);

	insert into cat.Agents (TenantId, Kind, [Name]) 
	output inserted.Id into @rtable(id)
	values (1, N'Company', N'Моє підприємство');
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
-- OPERATION GROUPS
begin
	set nocount on;
	declare @og table(Id nvarchar(16), [Order] int, [Name] nvarchar(255), Memo nvarchar(255));
	insert into @og (Id, [Order], [Name], [Memo]) values
		(N'Sales', 1, N'Продажі та маркетинг', N'Перелік операцій для продажів та маркетингу');
	merge doc.OperationGroups as t
	using @og as s on t.Id = s.Id and t.TenantId = 1
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], [Memo]) values
		(1, s.Id, s.[Order], s.[Name], s.Memo)
	when not matched by source and t.TenantId = 1 then delete;
end
go
-------------------------------------------------
-- DOCUMENT FORMS
begin
	set nocount on;
	declare @df table(Id nvarchar(16), [Name] nvarchar(255), [Url] nvarchar(255));
	insert into @df (Id, [Name], [Url]) values
		(N'invoice',    N'Рахунок клієнту', N'invoice'),
		(N'waybillout', N'Видаткова накладна', N'waybillout')
	merge doc.DocumentForms as t
	using @df as s on t.Id = s.Id and t.TenantId = 1
	when matched then update set
		t.[Name] = s.[Name],
		t.[Url] = s.[Url]
	when not matched by target then insert
		(TenantId, Id, [Name], [Url]) values
		(1, s.Id, s.[Name], s.[Url])
	when not matched by source and t.TenantId = 1 then delete;
end
go



