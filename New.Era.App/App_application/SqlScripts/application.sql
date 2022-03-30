/*
version: 10.1.1005
generated: 30.03.2022 13:26:46
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
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'jrn')
	exec sp_executesql N'create schema jrn';
go
------------------------------------------------
grant execute on schema::cat to public;
grant execute on schema::doc to public;
grant execute on schema::acc to public;
grant execute on schema::jrn to public;
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
	CodeUA nchar(4),
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
	IsStock bit not null
		constraint DF_Items_IsStock default(0),
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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Companies')
	create sequence cat.SQ_Companies as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Companies')
create table cat.Companies
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Companies_PK default(next value for cat.SQ_Companies),
	Void bit not null 
		constraint DF_Companies_Void default(0),
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Companies primary key (TenantId, Id)
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
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'FormsMenu')
create table doc.FormsMenu
(
	TenantId int not null,
	Id nvarchar(32) not null,
	[Name] nvarchar(255),
	[Category] nvarchar(32),
	[Order] int,
	[Memo] nvarchar(255),
		constraint PK_FormsMenu primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Forms')
create table doc.Forms
(
	TenantId int not null,
	Id nvarchar(16) not null,
	RowKinds nvarchar(255),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Forms primary key (TenantId, Id)
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
	Menu nvarchar(32) not null,
	Void bit not null 
		constraint DF_Operations_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Agent] nchar(1),
	Form nvarchar(16) not null,
	[WarehouseFrom] nchar(1),
	[WarehouseTo] nchar(1)
		constraint PK_Operations primary key (TenantId, Id),
		constraint FK_Operations_Menu_FormsMenu foreign key (TenantId, [Menu]) references doc.FormsMenu(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpJournal')
create table doc.OpJournal
(
	TenantId int not null,
	Id nvarchar(16) not null,
	Operation bigint not null,
	ApplyIf nvarchar(16),
	ApplyMode nchar(1), -- (S)um, (R)ow
	Direction nchar(1), -- (I)n, (O)ut, B(oth)
		constraint PK_OpJournal primary key (TenantId, Operation, Id),
		constraint FK_OpJournal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_OpJournalStore')
	create sequence doc.SQ_OpJournalStore as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpJournalStore')
create table doc.OpJournalStore
(
	TenantId int not null,
	Id bigint not null
		constraint DF_OpJournalStore_PK default(next value for doc.SQ_OpJournalStore),
	Operation bigint not null,
	RowKind nchar(4),
	IsIn bit,
	IsOut bit,
		constraint PK_OpJournalStore primary key (TenantId, Id, Operation),
		constraint FK_OpJournalStore_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
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
	[Date] datetime,
	Operation bigint not null,
	[Sum] money not null
		constraint DF_Documents_Sum default(0),
	Done bit not null
		constraint DF_Documents_Done default(0),
	Company bigint null,
	Agent bigint null,
	Memo nvarchar(255),
	DateApplied datetime,
		constraint PK_Documents primary key (TenantId, Id),
		constraint FK_Documents_Operation_Operations foreign key (TenantId, [Operation]) references doc.Operations(TenantId, Id),
		constraint FK_Documents_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_Documents_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_DocDetails')
	create sequence doc.SQ_DocDetails as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'DocDetails')
create table doc.DocDetails
(
	TenantId int not null,
	Id bigint not null
		constraint DF_DocDetails_PK default(next value for doc.SQ_DocDetails),
	[Document] bigint not null,
	RowNo int,
	Kind nchar(4),
	Item bigint null,
	Unit bigint null,
	Qty float null
		constraint DF_DocDetails_Qty default(0),
	Price money null,
	[Sum] money not null
		constraint DF_DocDetails_Sum default(0),
	Memo nvarchar(255),
		constraint PK_DocDetails primary key (TenantId, Id),
		constraint FK_DocDetails_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_DocDetails_Item_Items foreign key (TenantId, Item) references cat.Items(TenantId, Id),
		constraint FK_DocDetails_Unit_Units foreign key (TenantId, Unit) references cat.Units(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'jrn' and SEQUENCE_NAME = N'SQ_StockJournal')
	create sequence jrn.SQ_StockJournal as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal')
create table jrn.StockJournal
(
	TenantId int not null,
	Id bigint not null
		constraint DF_StockJournal_PK default(next value for jrn.SQ_StockJournal),
	Document bigint,
	Detail bigint,
	Company bigint null,
	Item bigint null,
	Dir smallint not null,
	Qty float null
		constraint DF_StockJournal_Qty default(0),
	[Sum] money not null
		constraint DF_StockJournal_Sum default(0),
		constraint PK_StockJournal primary key (TenantId, Id),
		constraint FK_StockJournal_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_StockJournal_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
		constraint FK_StockJournal_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id)
);
go

/*
drop table doc.DocDetails
drop table doc.Documents
drop table doc.Operations
drop table doc.Forms
drop table doc.FormsMenu
drop table cat.Agents
*/

/*
common
*/

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
		(90,    1,  90, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
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
		(1310,   13, 20, N'@[Planning]',       N'plan',      N'calendar', N'border-top'),
		(1311,   13, 21, N'@[Prices]',         N'price',     N'chart-column', null),
		(1320,   13, 30, N'@[Suppliers]',      N'agent',     N'users', N'border-top'),
		(1321,   13, 31, N'@[Items]',          N'item',      N'package-outline', null),
		(1322,   13, 32, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1330,   13, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1331,   13, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Accounting
		(1501,   15, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1502,   15, 11, N'@[BankAccounts]',   N'bankacc',   N'bank',  N'border-top'),
		(1503,   15, 12, N'@[AccountsPlan]',   N'plan',      N'account',  N'border-top'),
		(1504,   15, 13, N'@[Agents]',         N'agent',     N'users',  null),
		(1505,   15, 14, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1506,   15, 15, N'@[Journal]',        N'journal',   N'file-content',  N'border-top'),
		(1530,   15, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1531,   15, 41, N'@[Service]',        N'service',   N'gear-outline', null),

		-- Settings
		(9010,  90, 10, N'@[Companies]', N'company', N'company', null),
		(9011,  90, 12, N'@[Users]',     N'user',    N'user',    null),
		(901,   90, 14, N'@[AccountsPlan]',  N'accountplan', N'account',      N'border-top'),
		(902,   90, 14, N'@[Operations]',    N'operation',   N'file-content', null);

	exec a2ui.[MenuModule.Merge] @menu, 1, 9999;
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
-- Company
------------------------------------------------
create or alter procedure cat.[Company.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Companies!TCompany!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo
	from cat.Companies c
	where c.TenantId = @TenantId; 
end
go
------------------------------------------------
create or alter procedure cat.[Company.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Company!TCompany!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo
	from cat.Companies c
	where c.TenantId = @TenantId and c.Id = @Id;
end
go
-------------------------------------------------
drop procedure if exists cat.[Company.Metadata];
drop procedure if exists cat.[Company.Update];
drop type if exists cat.[Company.TableType];
go
-------------------------------------------------
create type cat.[Company.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Company.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Company cat.[Company.TableType];
	select [Company!Company!Metadata] = null, * from @Company;
end
go
------------------------------------------------
create or alter procedure cat.[Company.Update]
@TenantId int = 1,
@UserId bigint,
@Company cat.[Company.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Companies as t
	using @Company as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[FullName] = s.[FullName]
	when not matched by target then insert
		(TenantId, [Name], FullName, Memo) values
		(@TenantId, s.[Name], s.FullName, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Company.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
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
	[Memo] nvarchar(255),
	IsStock bit
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
		i.IsStock,
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
			t.Memo = s.Memo,
			t.IsStock = s.IsStock
	when not matched by target then 
		insert (TenantId, [Name], FullName, [Article], Memo, IsStock)
		values (@TenantId, s.[Name], FullName, Article, Memo, IsStock)
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
-------------------------------------------------
create or alter procedure cat.[Item.Browse.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Items!TItem!Array] = null, [Id!!Id] = i.Id, 
		[Name!!Name] = i.[Name], i.FullName, i.Article, i.Memo
	from cat.Items i
	order by Id;
end
go
/* Agent */
-------------------------------------------------
create or alter procedure cat.[Agent.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Agents!TAgent!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo]
	from cat.Agents a
	where TenantId = @TenantId;
end
go
-------------------------------------------------
create or alter procedure cat.[Agent.Load]
@TenantId int = 1,
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
		(TenantId, [Name], FullName, Memo) values
		(@TenantId, s.[Name], s.FullName, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Agent.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

/* UNIT */
drop procedure if exists cat.[Unit.Metadata];
drop procedure if exists cat.[Unit.Update];
drop type if exists cat.[Unit.TableType];
go
create type cat.[Unit.TableType] as table
(
	Id bigint,
	[Short] nvarchar(8),
	[CodeUA] nchar(4),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Unit.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Units!TUnit!Array] = null,
		[Id!!Id] = u.Id, [Name!!Name] = u.[Name], u.Memo, u.[Short], u.CodeUA
	from cat.Units u
	where TenantId = @TenantId
	order by u.Id;
end
go
------------------------------------------------
create or alter procedure cat.[Unit.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Unit!TUnit!Object] = null,
		[Id!!Id] = u.Id, [Name!!Name] = u.[Name], u.Memo, u.[Short], u.CodeUA
	from cat.Units u
	where u.TenantId = @TenantId and u.Id = @Id;
end
go
---------------------------------------------
create or alter procedure cat.[Unit.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Unit cat.[Unit.TableType];
	select [Unit!Unit!Metadata] = null, * from @Unit;
end
go
---------------------------------------------
create or alter procedure cat.[Unit.Update]
@TenantId int = 1,
@UserId bigint,
@Unit cat.[Unit.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Units as t
	using @Unit as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[Short] = s.[Short],
		t.[CodeUA] = s.[CodeUA]
	when not matched by target then insert
		(TenantId, [Name], Memo, Short, CodeUA) values
		(@TenantId, [Name], Memo, Short, CodeUA)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Unit.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
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

	select [Menu!TMenu!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo, Category,
		[Children!TOperation!LazyArray] = null
	from doc.FormsMenu
	where TenantId = @TenantId
	order by [Order], Id;

	-- children declaration. same as Children proc
	select [!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[Journals!TOpJournal!Array] = null
	from doc.Operations where 1 <> 1;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Children]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Children!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo
	from doc.Operations o 
	where TenantId = @TenantId and Menu = @Id
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
		[Menu], [Form],
		[Journals!TOpJournal!Array] = null,
		[JournalStore!TOpJournalStore!Array] = null
	from doc.Operations o 
	where o.TenantId = @TenantId and o.Id=@Id;

	select [!TOpJournal!Array]  =null, [Id!!Id] = Id,
		ApplyIf, ApplyMode, Direction,
		[!TOperation.Journals!ParentId] = oj.Operation
	from doc.OpJournal oj where oj.TenantId = @TenantId and oj.Operation = @Id;

	select [!TOpJournalStore!Array] = null, [Id!!Id] = Id, RowKind, IsIn, IsOut,
		[!TOperation.JournalStore!ParentId] = ojs.Operation
	from doc.OpJournalStore ojs 
	where ojs.TenantId = @TenantId and ojs.Operation = @Id;

	select [Forms!TForm!Array] = null, [Id!!Id] = df.Id, [Name!!Name] = df.[Name]
	from doc.Forms df
	where df.TenantId = @TenantId
	order by df.Id;

	select [Params!TParam!Object] = null, [ParentMenu] = @Parent;
end
go
-------------------------------------------------
drop procedure if exists doc.[Operation.Metadata];
drop procedure if exists doc.[Operation.Update];
drop type if exists doc.[Operation.TableType];
drop type if exists doc.[OpJournal.TableType];
drop type if exists doc.[OpJournalStore.TableType];
go
-------------------------------------------------
create type doc.[Operation.TableType]
as table(
	Id bigint null,
	[Menu] nvarchar(32),
	[Form] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
-------------------------------------------------
create type doc.[OpJournal.TableType]
as table(
	Id nvarchar(16),
	Operation bigint,
	ApplyIf nvarchar(16),
	ApplyMode nchar(1),
	Direction nchar(1)
)
go
-------------------------------------------------
create type doc.[OpJournalStore.TableType]
as table(
	Id bigint,
	RowKind nchar(4),
	IsIn bit,
	IsOut bit
)
go
------------------------------------------------
create or alter procedure doc.[Operation.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Operation doc.[Operation.TableType];
	declare @Journals doc.[OpJournal.TableType];
	declare @JournalStore doc.[OpJournalStore.TableType];
	select [Operation!Operation!Metadata] = null, * from @Operation;
	select [Journals!Operation.Journals!Metadata] = null, * from @Journals;
	select [JournalStore!Operation.JournalStore!Metadata] = null, * from @JournalStore;
end
go
------------------------------------------------
create or alter procedure doc.[Operation.Update]
@TenantId bigint = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Operation doc.[Operation.TableType] readonly,
@Journals doc.[OpJournal.TableType] readonly,
@JournalStore doc.[OpJournalStore.TableType] readonly
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
		t.[Form] = s.[Form]
	when not matched by target then insert
		(TenantId, [Menu], [Name], Form, Memo) values
		(@TenantId, s.[Menu], s.[Name], s.Form, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @Id = id from @rtable;

	merge doc.OpJournal as t
	using @Journals as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.Direction = s.Direction
	when not matched by target then insert
		(TenantId, Operation, Id, Direction) values
		(@TenantId, @Id, s.Id, s.Direction)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	merge doc.OpJournalStore as t
	using @JournalStore as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowKind = s.RowKind,
		t.IsIn = s.IsIn,
		t.IsOut = s.IsOut
	when not matched by target then insert
		(TenantId, Operation, RowKind, IsIn, IsOut) values
		(@TenantId, @Id, RowKind, s.IsIn, s.IsOut)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	exec doc.[Operation.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, @UserId = @UserId,
		@Id = @Id;
end
go

/* Document */
------------------------------------------------
create or alter procedure doc.[Document.Stock.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(255),
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Operation bigint = -1
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @docs table(rowno int identity(1, 1), id bigint, op bigint, agent bigint, 
		comp bigint, rowcnt int);

	insert into @docs(id, op, agent, comp, rowcnt)
	select d.Id, d.Operation, d.Agent, d.Company, 
		count(*) over()
	from doc.Documents d
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and o.Menu = @Menu
		and (@Operation = -1 or d.Operation = @Operation)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'date' then d.[Date]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'sum' then d.[Sum]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'date' then d.[Date]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'sum' then d.[Sum]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo],
		[Operation!TOperation!RefId] = d.Operation, 
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[!!RowCount] = t.rowcnt
	from @docs t inner join 
		doc.Documents d on d.TenantId = @TenantId and d.Id = t.id
	order by t.rowno;

	-- maps
	with T as (select op from @docs group by op)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form
	from doc.Operations o 
		inner join T t on o.TenantId = @TenantId and o.Id = op;

	with T as (select agent from @docs group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with T as (select comp from @docs group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	-- filters
	select [Forms!TForm!Array] = null, [Id!!Id] = f.Id, [Name!!Name] = f.[Name]
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
	where o.TenantId = @TenantId and o.Menu = @Menu
	group by f.Id, f.[Name]
	order by f.Id desc;

	-- filters
	select [Operations!TOperation!Array] = null, [Id!!Id] = -1, [Name!!Name] = N'@[Filter.AllOperations]', null, [!Order] = -1
	union all
	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form], [!Order] = o.Id
	from doc.Operations o
	where o.TenantId = @TenantId and o.Menu = @Menu
	order by [!Order];


	select [!$System!] = null, [!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Operation!Filter] = @Operation;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Form nvarchar(16) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docform nvarchar(16);
	if @Id is not null
		select @docform = o.Form 
		from doc.Documents d inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		where d.TenantId = @TenantId and d.Id = @Id;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company,
		[Rows!TRow!Array] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	declare @rows table(id bigint, item bigint);
	insert into @rows (id, item)
	select Id, Item from doc.DocDetails dd
	where dd.TenantId = @TenantId and dd.Document = @Id;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], Price, [Sum], 
		[Item!TItem!RefId] = Item, [Unit!TUnit!RefId] = Unit,
		[!TDocument.Rows!ParentId] = dd.Document, [RowNo!!RowNumber] = RowNo
	from doc.DocDetails dd
	where dd.TenantId=@TenantId and dd.Document = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form
	from doc.Operations o 
		left join doc.Documents d on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Documents d on d.TenantId = a.TenantId and d.Agent = a.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join doc.Documents d on d.TenantId = c.TenantId and d.Company = c.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	with T as (select item from @rows group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = [Name]
	from cat.Items i inner join T on i.Id = T.item and i.TenantId = @TenantId
	where i.TenantId = @TenantId;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form]
	from doc.Operations where Form = @Form or Form=@docform
	order by Id;
end
go
------------------------------------------------
drop procedure if exists doc.[Document.Stock.Metadata];
drop procedure if exists doc.[Document.Stock.Update];
drop type if exists cat.[Document.Stock.TableType];
drop type if exists cat.[Document.Stock.Row.TableType];
go
------------------------------------------------
create type cat.[Document.Stock.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Sum] money,
	Operation bigint,
	Agent bigint,
	Company bigint,
	Memo nvarchar(255)
)
go
------------------------------------------------
create type cat.[Document.Stock.Row.TableType]
as table(
	Id bigint null,
	ParentId bigint,
	RowNo int,
	Item bigint,
	[Qty] float,
	[Price] money,
	[Sum] money,
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
	declare @Rows cat.[Document.Stock.Row.TableType]
	select [Document!Document!Metadata] = null, * from @Document;
	select [Rows!Document.Rows!Metadata] = null, * from @Rows;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Update]
@TenantId int = 1,
@UserId bigint,
@Document cat.[Document.Stock.TableType] readonly,
@Rows cat.[Document.Stock.Row.TableType] readonly
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
		t.Operation = s.Operation,
		t.[Date] = s.[Date],
		t.[Sum] = s.[Sum],
		t.Company = s.Company,
		t.Agent = s.Agent,
		t.Memo = s.Memo
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, Memo) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	with DD as (select * from doc.DocDetails where TenantId = @TenantId and Document = @id)
	merge DD as t
	using @Rows as s on t.Id = s.Id
	when matched then update set
		t.RowNo = s.RowNo,
		t.Item = s.Item,
		t.Qty = s.Qty,
		t.Price = s.Price,
		t.[Sum] = s.[Sum]
	when not matched by target then insert
		(TenantId, Document, RowNo, Item, Qty, Price, [Sum]) values
		(@TenantId, @id, s.RowNo, s.Item, s.Qty, s.Price, s.[Sum])
	when not matched by source and t.TenantId = @TenantId and t.Document = @id then delete;

	exec doc.[Document.Stock.Load] @TenantId = @TenantId, 
	@UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.Stock]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	declare @dir nchar(1);
	select @dir = Direction from doc.OpJournal where TenantId = @TenantId and Operation = @Operation and Id=N'Stock';

	declare @journal table(Document bigint, Detail bigint, Company bigint, Item bigint, Qty float, [Sum] money);
	insert into @journal(Document, Detail, Company, Item, Qty, [Sum])
	select d.Id, dd.Id, d.Company, dd.Item, dd.Qty, dd.[Sum]
	from doc.DocDetails dd 
		inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
	where d.TenantId = @TenantId and d.Id = @Id;

	-- in, out, inout
	if @dir = N'O' or @dir = N'B'
		insert into jrn.StockJournal(TenantId, Dir, Document, Detail, Company, Item, Qty, [Sum])
		select @TenantId, -1, Document, Detail, Company, Item, Qty, [Sum]
		from @journal;
	else if @dir = N'I' or @dir = N'B'
		insert into jrn.StockJournal(TenantId, Dir, Document, Detail, Company, Item, Qty, [Sum])
		select @TenantId, 1, Document, Detail, Company, Item, Qty, [Sum]
		from @journal;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Apply]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @operation bigint;
	declare @done bit;
	select @operation = Operation, @done = Done from doc.Documents where TenantId = @TenantId and Id=@Id;
	if 1 = @done
		throw 60000, N'UI:@[Error.Document.AlreadyApplied]', 0;
	begin tran
		if exists(select * from doc.OpJournal where TenantId = @TenantId and Operation = @operation and Id=N'Stock')
			exec doc.[Document.Apply.Stock] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		update doc.Documents set Done = 1, DateApplied = getdate() 
			where TenantId = @TenantId and Id = @Id;
	commit tran

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
	declare @df table(Id nvarchar(16), [Name] nvarchar(255));
	insert into @df (Id, [Name]) values
		-- Sales
		(N'invoice',    N'Замовлення клієнта'),
		(N'waybillout', N'Видаткова накладна'),
		(N'complcert',  N'Акт виконаних робіт'),
		-- 
		(N'waybillin',  N'Прибуткова накладна'),
		--
		(N'payorder',  N'Платіжне доручення')
	merge doc.Forms as t
	using @df as s on t.Id = s.Id and t.TenantId = 1
	when matched then update set
		t.[Name] = s.[Name]
	when not matched by target then insert
		(TenantId, Id, [Name]) values
		(1, s.Id, s.[Name])
	when not matched by source and t.TenantId = 1 then delete;
end
go

-------------------------------------------------
-- Catalog
begin
	set nocount on;
	declare @cat table(Id int, Menu nvarchar(16), [Name] nvarchar(255), 
		[Order] int, Category nvarchar(32), [Memo] nvarchar(255), [Url] nvarchar(255), Icon nvarchar(16));
	insert into @cat (Id, Menu, [Order], [Category], [Name], [Url], Icon, Memo) values
	(100, N'Sales', 10, N'@[Items]', N'@[Units]', N'/catalog/unit/index', N'list',  N''),
	(101, N'Sales', 11, N'@[Items]', N'@[Vendors]', N'/catalog/vendor/index', N'list',  N''),

	(200, N'Purchase',   10, N'@[Items]',  N'@[Units]', N'/catalog/unit/index', N'list',  N''),
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


