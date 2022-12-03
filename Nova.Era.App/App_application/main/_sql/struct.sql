/*
main structure
*/
------------------------------------------------
begin
	set nocount on;
	declare @ver int = 7869;
	if exists(select * from a2sys.Versions where [Module]=N'ne:application')
		update a2sys.Versions set [Version]=@ver, [File]=N'app:sqlscripts\application.sql', Title=null where [Module]=N'ne:application';
	else
		insert into a2sys.Versions([Module], [Version], [File], Title) values (N'ne:application', @ver, N'app:sqlscripts\application.sql', null);
end
go
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
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'usr')
	exec sp_executesql N'create schema usr';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'rep')
	exec sp_executesql N'create schema rep';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'ini')
	exec sp_executesql N'create schema ini';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'ui')
	exec sp_executesql N'create schema ui';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'app')
	exec sp_executesql N'create schema app';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'crm')
	exec sp_executesql N'create schema crm';
go
------------------------------------------------
grant execute on schema::cat to public;
grant execute on schema::doc to public;
grant execute on schema::acc to public;
grant execute on schema::jrn to public;
grant execute on schema::usr to public;
grant execute on schema::rep to public;
grant execute on schema::ini to public;
grant execute on schema::ui  to public;
grant execute on schema::app to public;
grant execute on schema::crm to public;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'app' and SEQUENCE_NAME = N'SQ_Blobs')
	create sequence app.SQ_Blobs as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Blobs')
create table app.Blobs
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Blobs_Id default(next value for app.SQ_Blobs),
	[Stream] varbinary(max),
	[Name] nvarchar(255),
	[Mime] nvarchar(255),
	BlobName nvarchar(255),
	AccessToken uniqueidentifier
		constraint DF_Blobs_AccessToken default (newid()),
	constraint PK_Blobs primary key (TenantId, Id),
);
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
		constraint DF_Units_Id default(next value for cat.SQ_Units),
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
		constraint DF_Vendors_Id default(next value for cat.SQ_Vendors),
	Void bit not null 
		constraint DF_Vendors_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Vendors primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Brands')
	create sequence cat.SQ_Brands as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Brands')
create table cat.Brands
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Brands_Id default(next value for cat.SQ_Brands),
	Void bit not null 
		constraint DF_Brands_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Brands primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Projects')
	create sequence cat.SQ_Projects as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Projects')
create table cat.Projects
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Projects_Id default(next value for cat.SQ_Projects),
	Void bit not null 
		constraint DF_Projects_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Projects primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'cat' and SEQUENCE_NAME=N'SQ_Banks')
	create sequence cat.SQ_Banks as int start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Banks')
create table cat.Banks
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Banks_Id default(next value for cat.SQ_Banks),
	Void bit not null 
		constraint DF_Banks_Void default(0),
	[BankCode] nvarchar(16),
	[Code] nvarchar(16),
	[Name] nvarchar(255) null,
	[FullName] nvarchar(255) null,
	[Memo] nvarchar(255) null,
	IdExt nvarchar(64) null,
		constraint PK_Banks primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Currencies')
create table cat.Currencies
(
	TenantId int not null,
	Id bigint not null,
	Void bit not null 
		constraint DF_Currencies_Void default(0),
	Short nvarchar(8),
	[Alpha3] nchar(3),
	[Number3] nchar(3),
	Symbol nvarchar(3),
	[Denom] int,
	[Name] nvarchar(255) null,
	[Memo] nvarchar(255) null,
		constraint PK_Currencies primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Countries')
create table cat.Countries
(
	TenantId int not null,
	Code nchar(3) not null,
	Void bit not null 
		constraint DF_Countries_Void default(0),
	[Alpha2] nchar(2),
	[Alpha3] nchar(3),

	[Name] nvarchar(255) null,
	[Memo] nvarchar(255) null,
		constraint PK_Countries primary key (TenantId, Code)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'cat' and SEQUENCE_NAME=N'SQ_RespCenters')
	create sequence cat.SQ_RespCenters as int start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'RespCenters')
create table cat.RespCenters
(
	TenantId int not null,
	Id bigint not null
		constraint DF_RespCenters_Id default(next value for cat.SQ_RespCenters),
	Void bit not null 
		constraint DF_RespCenters_Void default(0),
	Parent bigint,
	IsFolder bit not null
		constraint DF_RespCenters_IsFolder default(0),
	[Name] nvarchar(255) null,
	[Memo] nvarchar(255) null,
		constraint PK_RespCenters primary key (TenantId, Id),
	constraint FK_RespCenters_Parent_RespCenters foreign key (TenantId, [Parent]) references cat.RespCenters(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'cat' and SEQUENCE_NAME=N'SQ_CostItems')
	create sequence cat.SQ_CostItems as int start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'CostItems')
create table cat.CostItems
(
	TenantId int not null,
	Id bigint not null
		constraint DF_CostItems_Id default(next value for cat.SQ_CostItems),
	Void bit not null 
		constraint DF_CostItems_Void default(0),
	Parent bigint,
	IsFolder bit not null
		constraint DF_CostItems_IsFolder default(0),
	[Name] nvarchar(255) null,
	[Memo] nvarchar(255) null,
	[Uid] uniqueidentifier not null
		constraint DF_CostItems_Uid default(newid()),
	constraint PK_CostItems primary key (TenantId, Id),
	constraint FK_CostItems_Parent_CostItems foreign key (TenantId, [Parent]) references cat.CostItems(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'cat' and SEQUENCE_NAME=N'SQ_CashFlowItems')
	create sequence cat.SQ_CashFlowItems as int start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'CashFlowItems')
create table cat.CashFlowItems
(
	TenantId int not null,
	Id bigint not null
		constraint DF_CashFlowItems_Id default(next value for cat.SQ_CostItems),
	Void bit not null 
		constraint DF_CashFlowItems_Void default(0),
	Parent bigint,
	IsFolder bit not null
		constraint DF_CashFlowItems_IsFolder default(0),
	[Name] nvarchar(255) null,
	[Memo] nvarchar(255) null,
	[Uid] uniqueidentifier not null
		constraint DF_CashFlowItems_Uid default(newid()),
	constraint PK_CashFlowItems primary key (TenantId, Id),
	constraint FK_CashFlowItems_Parent_CashFlowItems foreign key (TenantId, [Parent]) references cat.CashFlowItems(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_PriceKinds')
	create sequence cat.SQ_PriceKinds as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'PriceKinds')
create table cat.PriceKinds (
	TenantId int not null,
	Id bigint not null
		constraint DF_PriceKinds_Id default(next value for cat.SQ_PriceKinds),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Void bit not null 
		constraint DF_PriceKinds_Void default(0),
	Currency bigint,
	[Uid] uniqueidentifier not null
		constraint DF_PriceKinds_Uid default(newid()),
	constraint PK_PriceKinds primary key (TenantId, Id),
	constraint FK_PriceKinds_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id)
)
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'acc' and SEQUENCE_NAME = N'SQ_Accounts')
	create sequence acc.SQ_Accounts as bigint start with 10000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'acc' and TABLE_NAME=N'Accounts')
create table acc.Accounts (
	TenantId int not null,
	Id bigint not null
		constraint DF_Accounts_Id default(next value for acc.SQ_Accounts),
	Void bit not null 
		constraint DF_Accounts_Void default(0),
	[Plan] bigint null,
	Parent bigint null,
	IsFolder bit not null
		constraint DF_Accounts_IsFolder default(0),
	[Code] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	IsItem bit,
	IsAgent bit,
	IsWarehouse bit,
	IsBankAccount bit,
	IsCash bit,
	IsContract bit,
	IsRespCenter bit,
	IsCostItem bit,
	[Uid] uniqueidentifier not null
		constraint DF_Accounts_Uid default(newid()),
	constraint PK_Accounts primary key (TenantId, Id),
	constraint FK_Accounts_Parent_Accounts foreign key (TenantId, [Parent]) references acc.Accounts(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'acc' and SEQUENCE_NAME = N'SQ_AccKinds')
	create sequence acc.SQ_AccKinds as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'acc' and TABLE_NAME=N'AccKinds')
create table acc.AccKinds (
	TenantId int not null,
	Id bigint not null
		constraint DF_AccKinds_Id default(next value for acc.SQ_AccKinds),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Void bit not null 
		constraint DF_AccKinds_Void default(0),
	[Uid] uniqueidentifier not null
		constraint DF_AccKinds_Uid default(newid()),
	constraint PK_AccKinds primary key (TenantId, Id)
)
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_ItemRoles')
	create sequence cat.SQ_ItemRoles as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'ItemRoles')
create table cat.ItemRoles (
	TenantId int not null,
	Id bigint not null
		constraint DF_ItemRoles_Id default(next value for cat.SQ_ItemRoles),
	[Kind] nvarchar(16) not null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Void bit not null 
		constraint DF_ItemRoles_Void default(0),
	[Color] nvarchar(32),
	HasPrice bit,
	IsStock bit,
	ExType nchar(1), -- (C)ash, (B)ank, etc
	CostItem bigint,
	[Uid] uniqueidentifier not null
		constraint DF_ItemRoles_Uid default(newid()),
	constraint PK_ItemRoles primary key (TenantId, Id),
	constraint FK_ItemRoles_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id),
)
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_ItemRoleAccounts')
	create sequence cat.SQ_ItemRoleAccounts as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'ItemRoleAccounts')
create table cat.ItemRoleAccounts (
	TenantId int not null,
	Id bigint not null
		constraint DF_ItemRoleAccounts_Id default(next value for cat.SQ_ItemRoleAccounts),
	[Role] bigint not null,
	[Plan] bigint,
	[Account] bigint,
	[AccKind] bigint,

	constraint PK_ItemRoleAccounts primary key (TenantId, Id),
	constraint FK_ItemRoleAccounts_Role_ItemRoles foreign key (TenantId, [Role]) references cat.ItemRoles(TenantId, Id),
	constraint FK_ItemRoleAccounts_Plan_Accounts foreign key (TenantId, [Plan]) references acc.Accounts(TenantId, Id),
	constraint FK_ItemRoleAccounts_Account_Accounts foreign key (TenantId, [Account]) references acc.Accounts(TenantId, Id),
	constraint FK_ItemRoleAccounts_AccountKind_AccKinds foreign key (TenantId, [AccKind]) references acc.AccKinds(TenantId, Id)
)
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_ItemOptions')
	create sequence cat.SQ_ItemOptions as bigint start with 100 increment by 1;
go
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'ItemOptions')
create table cat.ItemOptions
(
	TenantId int not null,
	Id bigint not null
		constraint DF_ItemOptions_Id default(next value for cat.SQ_ItemOptions),
	Void bit not null
		constraint DF_ItemOptions_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_ItemOptions primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_ItemOptionValues')
	create sequence cat.SQ_ItemOptionValues as bigint start with 100 increment by 1;
go
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'ItemOptionValues')
create table cat.ItemOptionValues
(
	TenantId int not null,
	Id bigint not null
		constraint DF_ItemOptionValues_Id default(next value for cat.SQ_ItemOptionValues),
	Void bit not null
		constraint DF_ItemOptionValues_Void default(0),
	[Option] bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_ItemOptionValues primary key (TenantId, Id),
		constraint FK_ItemOptionValues_Option_ItemOptions foreign key (TenantId, [Option]) references cat.ItemOptions(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_ItemVariants')
	create sequence cat.SQ_ItemVariants as bigint start with 100 increment by 1;
go
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'ItemVariants')
create table cat.ItemVariants
(
	TenantId int not null,
	Id bigint not null
		constraint DF_ItemVariants_Id default(next value for cat.SQ_ItemVariants),
	[Option1] bigint,
	[Option2] bigint,
	[Option3] bigint,
	[Name] nvarchar(255),
	constraint PK_ItemVariants primary key (TenantId, Id),
	constraint FK_ItemVariants_Option1_ItemOptionValues foreign key (TenantId, [Option1]) references cat.ItemOptionValues(TenantId, Id),
	constraint FK_ItemVariants_Option2_ItemOptionValues foreign key (TenantId, [Option2]) references cat.ItemOptionValues(TenantId, Id),
	constraint FK_ItemVariants_Option3_ItemOptionValues foreign key (TenantId, [Option3]) references cat.ItemOptionValues(TenantId, Id)
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
		constraint DF_Items_Id default(next value for cat.SQ_Items),
	Void bit not null 
		constraint DF_Items_Void default(0),
	[Role] bigint not null, -- references cat.ItemRoles
	Article nvarchar(32),
	Barcode nvarchar(32),
	Unit bigint, -- base, references cat.Units
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	Vendor bigint, -- references cat.Vendors
	Brand bigint, -- references cat.Brands
	Country nchar(3), -- references cat.Countries
	Parent bigint,
	Variant bigint,
	IsVariant as (cast(case when [Parent] is not null then 1 else 0 end as bit)),
	[Uid] uniqueidentifier not null
		constraint DF_Items_Uid default(newid()),
	constraint PK_Items primary key (TenantId, Id),
	constraint FK_Items_Unit_Units foreign key (TenantId, Unit) references cat.Units(TenantId, Id),
	constraint FK_Items_Vendor_Vendors foreign key (TenantId, Vendor) references cat.Vendors(TenantId, Id),
	constraint FK_Items_Brand_Brands foreign key (TenantId, Brand) references cat.Brands(TenantId, Id),
	constraint FK_Items_Role_ItemRoles foreign key (TenantId, [Role]) references cat.ItemRoles(TenantId, Id),
	constraint FK_Items_Country_Countries foreign key (TenantId, Country) references cat.Countries(TenantId, Code),
	constraint FK_Items_Parent_Items foreign key (TenantId, [Parent]) references cat.Items(TenantId, Id),
	constraint FK_Items_Variant_ItemVariants foreign key (TenantId, Variant) references cat.ItemVariants(TenantId, Id)
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
		constraint DF_ItemTree_Id default(next value for cat.SQ_ItemTree),
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
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'ItemTreeElems')
create table cat.ItemTreeElems
(
	TenantId int not null,
	[Root] bigint not null,
	Parent bigint not null,
	Item bigint not null,
		constraint PK_ItemTreeElems primary key (TenantId, Parent, Item),
		constraint FK_ItemTreeElems_Root_ItemTree foreign key (TenantId, [Root]) references cat.ItemTree(TenantId, Id),
		constraint FK_ItemTreeElems_Parent_ItemTree foreign key (TenantId, [Parent]) references cat.ItemTree(TenantId, Id),
		constraint FK_ItemTreeElems_Item_Items foreign key (TenantId, [Item]) references cat.Items(TenantId, Id)
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
		constraint DF_Companies_Id default(next value for cat.SQ_Companies),
	Void bit not null 
		constraint DF_Companies_Void default(0),
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	Logo bigint null,
	[AutonumPrefix] nvarchar(8),
		constraint PK_Companies primary key (TenantId, Id),
		constraint FK_Companies_Logo_Blobs foreign key (TenantId, Logo) references app.Blobs(TenantId, Id)
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
		constraint DF_Agents_Id default(next value for cat.SQ_Agents),
	Void bit not null 
		constraint DF_Agents_Void default(0),
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	[Partner] bit,
	[Person] bit,
	-- roles
	IsSupplier bit,
	IsCustomer bit,
		constraint PK_Agents primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Contacts')
	create sequence cat.SQ_Contacts as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Contacts')
create table cat.Contacts
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Contacts_Id default(next value for cat.SQ_Contacts),
	Void bit not null 
		constraint DF_Contacts_Void default(0),
	[Name] nvarchar(255),
	[Position] nvarchar(255),
	Gender nchar(1), -- F/M/U
	Birthday date,
	Country nchar(3),
	Email nvarchar(64),
	Phone nvarchar(32),	
	[Address] nvarchar(255), 
	[Memo] nvarchar(255),
	UserCreated bigint not null,
	UtcDateCreated datetime not null 
		constraint DF_Contacts_UtcDateCreated default(getutcdate()),
	UserModified bigint not null,
	UtcDateModified datetime not null,
	ExternalId nvarchar(64) null,
	constraint PK_Contacts primary key (TenantId, Id),
	constraint FK_Contacts_Country_Countries foreign key (TenantId, Country) references cat.Countries(TenantId, Code),
	constraint FK_Contacts_UserCreated_Users foreign key (TenantId, UserCreated) references appsec.Users(Tenant, Id),
	constraint FK_Contacts_UserModified_Users foreign key (TenantId, UserModified) references appsec.Users(Tenant, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'AgentContacts')
create table cat.AgentContacts
(
	TenantId int not null,
	Agent bigint,
	Contact bigint,
	constraint PK_AgentContacts primary key (TenantId, Agent, Contact)
)
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Warehouses')
	create sequence cat.SQ_Warehouses as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Warehouses')
create table cat.Warehouses
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Warehouses_Id default(next value for cat.SQ_Warehouses),
	Void bit not null 
		constraint DF_Warehouses_Void default(0),
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	RespPerson bigint,
		constraint PK_Warehouses primary key (TenantId, Id),
		constraint FK_Warehouses_RespPerson_Agents foreign key (TenantId, RespPerson) references cat.Agents(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_CashAccounts')
	create sequence cat.SQ_CashAccounts as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'CashAccounts')
create table cat.CashAccounts
(
	TenantId int not null,
	Id bigint not null
		constraint DF_CashAccounts_Id default(next value for cat.SQ_CashAccounts),
	Void bit not null 
		constraint DF_CashAccounts_Void default(0),
	IsCashAccount bit not null,
	Company bigint not null,
	Currency bigint not null,
	ItemRole bigint not null,
	[Name] nvarchar(255),
	[Bank] bigint,
	[AccountNo] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_CashAccounts primary key (TenantId, Id),
		constraint FK_CashAccounts_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_CashAccounts_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id),
		constraint FK_CashAccounts_Bank_Banks foreign key (TenantId, Bank) references cat.Banks(TenantId, Id),
		constraint FK_CashAccounts_ItemRole_ItemRoles foreign key (TenantId, ItemRole) references cat.ItemRoles(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'crm' and SEQUENCE_NAME = N'SQ_LeadStages')
	create sequence crm.SQ_LeadStages as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'crm' and TABLE_NAME=N'LeadStages')
create table crm.LeadStages (
	TenantId int not null,
	[Id] bigint not null
		constraint DF_LeadStages_Id default(next value for crm.SQ_LeadStages),
	Void bit not null 
		constraint DF_LeadStages_Void default(0),
	[Order] int,
	[Kind] nchar(1), -- (I)nit, (P)rocess, [S]uccess, F(ail)
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Memo] nvarchar(255),
	constraint PK_LeadStages primary key (TenantId, [Id])
);
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'crm' and SEQUENCE_NAME = N'SQ_Leads')
	create sequence crm.SQ_Leads as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'crm' and TABLE_NAME=N'Leads')
create table crm.Leads (
	TenantId int not null,
	[Id] bigint not null
		constraint DF_Leads_Id default(next value for crm.SQ_Leads),
	Void bit not null 
		constraint DF_Leads_Void default(0),
	Stage bigint,
	Contact bigint,
	Agent bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Amount money,
	Currency bigint,
	ExternalId nvarchar(64),
	UserCreated bigint not null,
	UtcDateCreated datetime not null 
		constraint DF_Leads_UtcDateCreated default(getutcdate()),
	UserModified bigint not null,
	UtcDateModified datetime not null,
	constraint PK_Leads primary key (TenantId, [Id]),
	constraint FK_Leads_Stage_LeadStages foreign key (TenantId, Stage) references crm.LeadStages(TenantId, Id),
	constraint FK_Leads_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id),
	constraint FK_Leads_Contact_Contacts foreign key (TenantId, Contact) references cat.Contacts(TenantId, Id),
	constraint FK_Leads_Agent_Agnets foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
	constraint FK_Leads_UserCreated_Users foreign key (TenantId, UserCreated) references appsec.Users(Tenant, Id),
	constraint FK_Leads_UserModified_Users foreign key (TenantId, UserModified) references appsec.Users(Tenant, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_Autonums')
	create sequence doc.SQ_Autonums as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Autonums')
create table doc.Autonums (
	TenantId int not null,
	[Id] bigint not null
		constraint DF_Autonum_Id default(next value for doc.SQ_Autonums),
	Void bit not null 
		constraint DF_Autonum_Void default(0),
	[Name] nvarchar(255),
	[Period] nchar(1) not null, -- (A)ll, (Y)ear, Q(uart), M(onth)
	Pattern nvarchar(255), -- yyyy, yy, MM, qq, n(*), p
	[Memo] nvarchar(255),
	[Uid] uniqueidentifier not null
		constraint DF_Autonum_Uid default(newid()),
		constraint PK_Autonum primary key (TenantId, [Id])
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'AutonumValues')
create table doc.AutonumValues (
	TenantId int not null,
	[Company] bigint not null,
	[Autonum] bigint not null,
	[Year] int not null,
	[Quart] int not null,
	[Month] int not null,
	CurrentNumber int null,
		constraint PK_AutonumValues primary key (TenantId, Company, [Autonum], [Year], Quart, [Month]),
		constraint FK_AutonumValues_Autonum_Autonum foreign key (TenantId, Autonum) references doc.Autonums(TenantId, Id),
		constraint FK_AutonumValues_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_Prices')
	create sequence doc.SQ_Prices as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Prices')
create table doc.Prices (
	TenantId int not null,
	Id bigint not null
		constraint DF_Prices_Id default(next value for doc.SQ_Prices),
	[Date] date not null,
	PriceKind bigint not null,
	Item bigint not null,
	Currency bigint not null,
	Price float not null,

	constraint PK_Prices primary key (TenantId, Id),
	constraint FK_Prices_PriceKind_PriceKinds foreign key (TenantId, PriceKind) references cat.PriceKinds(TenantId, Id),
	constraint FK_Prices_Item_Items foreign key (TenantId, Item) references cat.Items(TenantId, Id),
	constraint FK_Prices_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id)
)
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'ContractKinds')
create table doc.ContractKinds
(
	TenantId int not null,
	Id nvarchar(16) not null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Order] int,
		constraint PK_ContractKinds primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_Contracts')
	create sequence doc.SQ_Contracts as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Contracts')
create table doc.Contracts
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Contracts_Id default(next value for doc.SQ_Contracts),
	Agent bigint,
	SNo nvarchar(255),
	[Name] nvarchar(255),
	[Date] date,
	Company bigint,
	PriceKind bigint,
	Kind nvarchar(16),
	Currency bigint,
	Void bit not null 
		constraint DF_Contracts_Void default(0),
	[Memo] nvarchar(255),

	constraint PK_Contracts primary key (TenantId, Id),
	constraint FK_Contracts_Kind_ContractKinds foreign key (TenantId, Kind) references doc.ContractKinds(TenantId, Id),
	constraint FK_Contracts_PriceKind_PriceKinds foreign key (TenantId, PriceKind) references cat.PriceKinds(TenantId, Id),
	constraint FK_Contracts_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
	constraint FK_Contracts_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
	constraint FK_Contracts_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id)
)
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
	[Url] nvarchar(255),
	[Order] int,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Category nvarchar(255),
	InOut smallint,
	HasState bit,
	constraint PK_Forms primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'PrintForms')
create table doc.PrintForms
(
	TenantId int not null,
	Id nvarchar(16) not null,
	[Order] int,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Url] nvarchar(255),
	[Report] nvarchar(255),
	Category nvarchar(255),
		constraint PK_PrintForms primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'FormRowKinds')
create table doc.FormRowKinds
(
	TenantId int not null,
	Id nvarchar(16) not null,
	Form nvarchar(16) not null,
	[Order] int,
	[Name] nvarchar(255),
	constraint PK_FormRowKinds primary key (TenantId, Form, Id),
	constraint FK_FormRowKinds_Form_Forms foreign key (TenantId, [Form]) references doc.Forms(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_DocStates')
	create sequence doc.SQ_DocStates as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'DocStates')
create table doc.DocStates (
	TenantId int not null,
	[Id] bigint not null
		constraint DF_DocStates_Id default(next value for doc.SQ_DocStates),
	Form nvarchar(16) not null,
	Void bit not null 
		constraint DF_DocStates_Void default(0),
	[Order] int,
	[Kind] nchar(1), -- (I)nit, (P)rocess, [S]uccess, C(ancel)
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Memo] nvarchar(255),
	constraint PK_DocStates primary key (TenantId, [Id]),
	constraint FK_DocStates_Form_Forms foreign key (TenantId, [Form]) references doc.Forms(TenantId, Id)
);
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OperationKinds')
create table doc.OperationKinds
(
	TenantId int not null,
	Id nvarchar(16) not null,
	[Order] int,
	Kind nvarchar(16),
	Factor smallint,
	LinkType nchar(1), -- (B)ase, (P)arent
	[Name] nvarchar(255),
		constraint PK_OperationKinds primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_Operations')
	create sequence doc.SQ_Operations as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations')
create table doc.Operations
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Operations_Id default(next value for doc.SQ_Operations),
	Void bit not null 
		constraint DF_Operations_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Form nvarchar(16) not null,
	[DocumentUrl] nvarchar(255) null,
	[Autonum] bigint,
	[Kind] nvarchar(16),
	[Uid] uniqueidentifier not null
		constraint DF_Operations_Uid default(newid()),
	constraint PK_Operations primary key (TenantId, Id),
	constraint FK_Operations_Form_Forms foreign key (TenantId, Form) references doc.Forms(TenantId, Id),
	constraint FK_Operations_Autonum_Autonums foreign key (TenantId, Autonum) references doc.Autonums(TenantId, Id),
	constraint FK_Operations_Kind_OperationKinds foreign key (TenantId, Kind) references doc.OperationKinds(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_OperationLinks')
	create sequence doc.SQ_OperationLinks as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OperationLinks')
create table doc.OperationLinks
(
	TenantId int not null,
	Id bigint not null
		constraint DF_OperationLinks_Id default(next value for doc.SQ_OperationLinks),
	Category nvarchar(32) not null,
	Parent bigint not null,
	Operation bigint not null,
	Memo nvarchar(255),
	[Type] nvarchar(32),
	constraint PK_OperationLinks primary key (TenantId, Id),
	constraint FK_OperationLinks_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id),
	constraint FK_OperationLinks_Parent_Operations foreign key (TenantId, Parent) references doc.Operations(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_OpStore')
	create sequence doc.SQ_OpStore as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpStore')
create table doc.OpStore
(
	TenantId int not null,
	Id bigint not null
		constraint DF_OpStore_Id default(next value for doc.SQ_OpStore),
	Operation bigint not null,
	RowNo int,
	RowKind nvarchar(16) not null,
	IsIn bit not null,
	IsOut bit not null,
	Factor smallint -- 1 normal, -1 storno
		constraint CK_OpStore_Factor check (Factor in (1, -1)),
	constraint PK_OpStore primary key (TenantId, Id, Operation),
	constraint FK_OpStore_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_OpTrans')
	create sequence doc.SQ_OpTrans as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpTrans')
create table doc.OpTrans
(
	TenantId int not null,
	Id bigint not null
		constraint DF_OpTrans_Id default(next value for doc.SQ_OpTrans),
	Operation bigint not null,
	RowNo int,
	RowKind nvarchar(16) not null,
	[Plan] bigint not null,
	Dt bigint null,
	Ct bigint null,
	DtAccMode nchar(1), -- ()Fixed, R(ole)
	DtSum nchar(1), -- ()Sum, (D)iscount, (W)Without discount, (V)at
	DtRow nchar(1), -- ()Sum, (R)ows
	DtAccKind bigint,
	DtWarehouse nchar(1),
	CtAccMode nchar(1),
	CtSum nchar(1),
	CtRow nchar(1),
	CtAccKind bigint,
	CtWarehouse nchar(1),
	Factor smallint -- 1 normal, -1 storno
		constraint CK_OpTrans_Factor check (Factor in (1, -1))
		constraint DF_OpTrans_Factor default (1),
	constraint PK_OpTrans primary key (TenantId, Id, Operation),
	constraint FK_OpTrans_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id),
	constraint FK_OpTrans_Plan_Accounts foreign key (TenantId, [Plan]) references acc.Accounts(TenantId, Id),
	constraint FK_OpTrans_Dt_Accounts foreign key (TenantId, [Dt]) references acc.Accounts(TenantId, Id),
	constraint FK_OpTrans_Ct_Accounts foreign key (TenantId, [Ct]) references acc.Accounts(TenantId, Id),
	constraint FK_OpTrans_DtAccKind_ItemRoles foreign key (TenantId, DtAccKind) references acc.AccKinds(TenantId, Id),
	constraint FK_OpTrans_CtAccKind_ItemRoles foreign key (TenantId, CtAccKind) references acc.AccKinds(TenantId, Id),
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_OpCash')
	create sequence doc.SQ_OpCash as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpCash')
create table doc.OpCash
(
	TenantId int not null,
	Id bigint not null
		constraint DF_OpCash_Id default(next value for doc.SQ_OpCash),
	Operation bigint not null,
	IsIn bit not null,
	IsOut bit not null,
	Factor smallint -- 1 normal, -1 storno
		constraint CK_OpCash_Factor check (Factor in (1, -1)),
	constraint PK_OpCash primary key (TenantId, Id, Operation),
	constraint FK_OpCash_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_OpSettle')
	create sequence doc.SQ_OpSettle as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpSettle')
create table doc.OpSettle
(
	TenantId int not null,
	Id bigint not null
		constraint DF_OpSettle_Id default(next value for doc.SQ_OpSettle),
	Operation bigint not null,
	IsInc bit not null,
	IsDec bit not null,
	Factor smallint -- 1 normal, -1 storno
		constraint CK_OpSettle_Factor check (Factor in (1, -1)),
	constraint PK_OpSettle primary key (TenantId, Id, Operation),
	constraint FK_OpSettle_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'ui' and TABLE_NAME=N'OpMenuLinks')
create table ui.OpMenuLinks
(
	TenantId int not null,
	Operation bigint not null,
	Menu nvarchar(32) not null,

	constraint PK_OpMenuLinks primary key (TenantId, Operation, Menu),
	constraint FK_OpMenuLinks_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpPrintForms')
create table doc.OpPrintForms
(
	TenantId int not null,
	Operation bigint not null,
	PrintForm nvarchar(16) not null,
	constraint PK_OpPrintForms primary key (TenantId, Operation, PrintForm),
	constraint FK_OpPrintForms_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id),
	constraint FK_OpPrintForms_PrintForm_PrintForms foreign key (TenantId, PrintForm) references doc.PrintForms(TenantId, Id)
);
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
		constraint DF_Documents_Id default(next value for doc.SQ_Documents),
	[Date] datetime,
	Operation bigint not null,
	[Sum] money not null
		constraint DF_Documents_Sum default(0),
	[No] nvarchar(64),
	[SNo] nvarchar(64),
	Done bit not null
		constraint DF_Documents_Done default(0),
	Temp bit not null
		constraint DF_Documents_Temp default(0),
	[Parent] bigint,
	[Base] bigint,
	OpLink bigint,
	[State] bigint,
	BindKind nvarchar(16),
	BindFactor smallint,
	Company bigint null,
	Agent bigint null,
	[Contract] bigint null,
	Currency bigint null,
	WhFrom bigint null,
	WhTo bigint  null,
	CashAccFrom bigint null,
	CashAccTo bigint null,
	RespCenter bigint null,
	ItemRole bigint null,
	CostItem bigint null,
	CashFlowItem bigint null,
	PriceKind bigint null,
	Project bigint null,
	Notice nvarchar(255),
	Memo nvarchar(255),
	DateApplied datetime,
	UserCreated bigint not null,
	UtcDateCreated datetime not null 
		constraint DF_Documents_UtcDateCreated default(getutcdate()),
	constraint PK_Documents primary key (TenantId, Id),
	constraint FK_Documents_Parent_Documents foreign key (TenantId, [Parent]) references doc.Documents(TenantId, Id),
	constraint FK_Documents_Base_Documents foreign key (TenantId, [Base]) references doc.Documents(TenantId, Id),
	constraint FK_Documents_OpLink_OperationLinks foreign key (TenantId, OpLink) references doc.OperationLinks(TenantId, Id),
	constraint FK_Documents_Operation_Operations foreign key (TenantId, [Operation]) references doc.Operations(TenantId, Id),
	constraint FK_Documents_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
	constraint FK_Documents_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
	constraint FK_Documents_Contract_Contracts foreign key (TenantId, Contract) references doc.Contracts(TenantId, Id),
	constraint FK_Documents_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id),
	constraint FK_Documents_WhFrom_Warehouses foreign key (TenantId, WhFrom) references cat.Warehouses(TenantId, Id),
	constraint FK_Documents_WhTo_Warehouses foreign key (TenantId, WhTo) references cat.Warehouses(TenantId, Id),
	constraint FK_Documents_CashAccFrom_CashAccounts foreign key (TenantId, CashAccFrom) references cat.CashAccounts(TenantId, Id),
	constraint FK_Documents_CashAccTo_CashAccounts foreign key (TenantId, CashAccTo) references cat.CashAccounts(TenantId, Id),
	constraint FK_Documents_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id),
	constraint FK_Documents_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id),
	constraint FK_Documents_CashFlowItem_CashFlowItems foreign key (TenantId, CashFlowItem) references cat.CashFlowItems(TenantId, Id),
	constraint FK_Documents_PriceKind_PriceKinds foreign key (TenantId, PriceKind) references cat.PriceKinds(TenantId, Id),
	constraint FK_Documents_UserCreated_Users foreign key (TenantId, UserCreated) references appsec.Users(Tenant, Id),
	constraint FK_Documents_ItemRole_ItemRoles foreign key (TenantId, ItemRole) references cat.ItemRoles(TenantId, Id),
	constraint FK_Documents_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id),
	constraint FK_Documents_State_DocStates foreign key (TenantId, [State]) references doc.DocStates(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'DocumentExtra')
create table doc.DocumentExtra
(
	TenantId int not null,
	Id bigint not null,
	WriteSupplierPrices bit,
	IncludeServiceInCost bit,
	constraint PK_DocumentExtra primary key (TenantId, Id),
	constraint FK_DocumentExtra_Id_Documents foreign key (TenantId, Id) references doc.Documents(TenantId, Id),
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
		constraint DF_DocDetails_Id default(next value for doc.SQ_DocDetails),
	[Document] bigint not null,
	RowNo int,
	Kind nvarchar(16),
	Item bigint null,
	ItemRole bigint null,
	ItemRoleTo bigint null,
	Unit bigint null,
	Qty float not null
		constraint DF_DocDetails_Qty default(0),
	FQty float not null
		constraint DF_DocDetails_FQty default(0),
	Price money null,
	[Sum] money not null
		constraint DF_DocDetails_Sum default(0),
	[ESum] money not null -- extra sum
		constraint DF_DocDetails_ESum default(0),
	[DSum] money null -- discount sum
		constraint DF_DocDetails_DSum default(0),
	[TSum] money null -- total sum
		constraint DF_DocDetails_TSum default(0),
	Memo nvarchar(255),
		constraint PK_DocDetails primary key (TenantId, Id),
	CostItem bigint,
	constraint FK_DocDetails_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
	constraint FK_DocDetails_Item_Items foreign key (TenantId, Item) references cat.Items(TenantId, Id),
	constraint FK_DocDetails_ItemRole_ItemRoles foreign key (TenantId, ItemRole) references cat.ItemRoles(TenantId, Id),
	constraint FK_DocDetails_ItemRoleTo_ItemRoles foreign key (TenantId, ItemRoleTo) references cat.ItemRoles(TenantId, Id),
	constraint FK_DocDetails_Unit_Units foreign key (TenantId, Unit) references cat.Units(TenantId, Id),
	constraint FK_DocDetails_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'jrn' and SEQUENCE_NAME = N'SQ_CashJournal')
	create sequence jrn.SQ_CashJournal as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'CashJournal')
create table jrn.CashJournal
(
	TenantId int not null,
	Id bigint not null
		constraint DF_CashJournal_Id default(next value for jrn.SQ_CashJournal),
	[Date] datetime not null,
	Document bigint not null,
	Operation bigint,
	Detail bigint,
	InOut smallint not null,
	Company bigint not null,
	Agent bigint null,
	[Contract] bigint null,
	CashAccount bigint not null,
	CashFlowItem bigint null,
	RespCenter bigint null,
	Project bigint,
	[Sum] money not null
		constraint DF_CashJournal_Sum default(0),
	_SumIn as (case when InOut = 1 then [Sum] else 0 end),
	_SumOut as (case when InOut = -1 then [Sum] else 0 end),
		constraint PK_CashJournal primary key (TenantId, Id),
		constraint FK_CashJournal_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_CashJournal_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
		constraint FK_CashJournal_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_CashJournal_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
		constraint FK_CashJournal_Contract_Contracts foreign key (TenantId, Contract) references doc.Contracts(TenantId, Id),
		constraint FK_CashJournal_CashAccount_CashAccounts foreign key (TenantId, CashAccount) references cat.CashAccounts(TenantId, Id),
		constraint FK_CashJournal_CashFlowItem_CashFlowItems foreign key (TenantId, CashFlowItem) references cat.CashFlowItems(TenantId, Id),
		constraint FK_CashJournal_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id),
		constraint FK_CashJournal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id),
		constraint FK_CashJournal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'CashReminders')
create table jrn.CashReminders
(
	TenantId int not null,
	CashAccount bigint not null,
	[Sum] money not null
		constraint PK_CashReminders primary key (TenantId, CashAccount),
		constraint FK_CashReminders_CashAccount_CashAccounts foreign key (TenantId, CashAccount) references cat.CashAccounts(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'jrn' and SEQUENCE_NAME = N'SQ_SettleJournal')
	create sequence jrn.SQ_SettleJournal as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'SettleJournal')
create table jrn.SettleJournal
(
	TenantId int not null,
	Id bigint not null
		constraint DF_SettleJournal_Id default(next value for jrn.SQ_SettleJournal),
	[Date] datetime not null,
	Document bigint not null,
	Operation bigint,
	Detail bigint,
	IncDec smallint not null,
	Company bigint not null,
	Agent bigint null,
	[Contract] bigint null,
	RespCenter bigint null,
	Project bigint,
	[Sum] money not null
		constraint DF_SettleJournal_Sum default(0),
	[CSum] money not null
		constraint DF_SettleJournal_CSum default(0),
	[Currency] bigint,
	_SumInc as (case when IncDec = 1 then [Sum] else 0 end),
	_SumDec as (case when IncDec = -1 then [Sum] else 0 end),
		constraint PK_SettleJournal primary key (TenantId, Id),
		constraint FK_SettleJournal_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_SettleJournal_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
		constraint FK_SettleJournal_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_SettleJournal_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
		constraint FK_SettleJournal_Contract_Contracts foreign key (TenantId, Contract) references doc.Contracts(TenantId, Id),
		constraint FK_SettleJournal_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id),
		constraint FK_SettleJournal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id),
		constraint FK_SettleJournal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
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
		constraint DF_StockJournal_Id default(next value for jrn.SQ_StockJournal),
	Document bigint,
	Operation bigint,
	Detail bigint,
	Company bigint null,
	Agent bigint null,
	[Contract] bigint null,
	Warehouse bigint null,
	Item bigint null,
	Dir smallint not null,
	Qty float null
		constraint DF_StockJournal_Qty default(0),
	[Sum] money not null
		constraint DF_StockJournal_Sum default(0),
	CostItem bigint,
	RespCenter bigint,
	Project bigint,
		constraint PK_StockJournal primary key (TenantId, Id),
		constraint FK_StockJournal_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_StockJournal_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
		constraint FK_StockJournal_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_StockJournal_Warehouse_Warehouses foreign key (TenantId, Warehouse) references cat.Warehouses(TenantId, Id),
		constraint FK_StockJournal_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id),
		constraint FK_StockJournal_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id),
		constraint FK_StockJournal_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
		constraint FK_StockJournal_Contract_Contracts foreign key (TenantId, [Contract]) references doc.Contracts(TenantId, Id),
		constraint FK_StockJournal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id),
		constraint FK_StockJournal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'jrn' and SEQUENCE_NAME = N'SQ_Journal')
	create sequence jrn.SQ_Journal as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'Journal')
create table jrn.Journal
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Journal_Id default(next value for jrn.SQ_Journal),
	TrNo int not null,
	RowNo int,
	[Date] datetime,
	Document bigint,
	Operation bigint,
	Detail bigint,
	DtCt smallint not null,
	[Plan] bigint not null,
	Account bigint not null,
	CorrAccount bigint not null,
	Company bigint null,
	Warehouse bigint null,
	Agent bigint null,
	[Contract] bigint null,
	Item bigint null,
	CashAccount bigint null,
	CostItem bigint null,
	CashFlowItem bigint null,
	RespCenter bigint null,
	Project bigint null,
	Qty float null,
	[Sum] money not null
		constraint DF_Journal_Sum default(0),
	_SumDt as (case when DtCt = 1 then [Sum] else 0 end),
	_SumCt as (case when DtCt = -1 then [Sum] else 0 end),
	_QtyDt as (case when DtCt = 1 then [Qty] else 0 end),
	_QtyCt as (case when DtCt = -1 then [Qty] else 0 end),
		constraint PK_Journal primary key (TenantId, Id),
		constraint FK_Journal_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_Journal_Plan_Accounts foreign key (TenantId, [Plan]) references acc.Accounts(TenantId, Id),
		constraint FK_Journal_Account_Accounts foreign key (TenantId, Account) references acc.Accounts(TenantId, Id),
		constraint FK_Journal_CorrAccount_Accounts foreign key (TenantId, CorrAccount) references acc.Accounts(TenantId, Id),
		constraint FK_Journal_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
		constraint FK_Journal_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_Journal_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
		constraint FK_Journal_Contract_Contracts foreign key (TenantId, Contract) references doc.Contracts(TenantId, Id),
		constraint FK_Journal_Warehouse_Warehouses foreign key (TenantId, Warehouse) references cat.Warehouses(TenantId, Id),
		constraint FK_Journal_CashAccount_CashAccounts foreign key (TenantId, CashAccount) references cat.CashAccounts(TenantId, Id),
		constraint FK_Journal_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id),
		constraint FK_Journal_CashFlowItem_CashFlowItems foreign key (TenantId, CashFlowItem) references cat.CashFlowItems(TenantId, Id),
		constraint FK_Journal_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id),
		constraint FK_Journal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id),
		constraint FK_Journal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'SupplierPrices')
create table jrn.SupplierPrices
(
	TenantId int not null,
	[Date] date not null,
	Item bigint not null,
	[Agent] bigint not null,
	Document bigint,
	Detail bigint,
	Price float not null,
		constraint PK_SupplierPrices primary key (TenantId, [Date], Item),
		constraint FK_SupplierPrices_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_SupplierPrices_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
		constraint FK_SupplierPrices_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
		constraint FK_SupplierPrices_Items_Item foreign key (TenantId, Item) references cat.Items(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'rep' and TABLE_NAME=N'RepTypes')
create table rep.RepTypes
(
	TenantId int not null,
	Id nvarchar(16) not null,
	[Order] int,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[UseAccount] bit,
	[UsePlan] bit,
	constraint PK_RepTypes primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'rep' and TABLE_NAME=N'RepFiles')
create table rep.RepFiles
(
	TenantId int not null,
	Id nvarchar(16) not null,
	[Type] nvarchar(16) not null,
	[Name] nvarchar(255),
	[Url] nvarchar(255),
	[Order] int,
	constraint PK_RepFiles primary key (TenantId, Id),
	constraint FK_RepFiles_Type_RepTypes foreign key (TenantId, [Type]) references rep.RepTypes(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'rep' and SEQUENCE_NAME = N'SQ_Reports')
	create sequence rep.SQ_Reports as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'rep' and TABLE_NAME=N'Reports')
create table rep.Reports
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Reports_Id default(next value for rep.SQ_Reports),
	Void bit not null 
		constraint DF_Reports_Void default(0),
	[Type] nvarchar(16) not null,
	[File] nvarchar(16),
	Account bigint,
	[Menu] nvarchar(32),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Uid] uniqueidentifier not null
		constraint DF_Reports_Uid default(newid()),

	constraint PK_Reports primary key (TenantId, Id),
	constraint FK_Reports_Type_RepTypes foreign key (TenantId, [Type]) references rep.RepTypes(TenantId, Id),
	constraint FK_Reports_File_RepFiles foreign key (TenantId, [File]) references rep.RepFiles(TenantId, Id),
	constraint FK_Reports_Account_Accounts foreign key (TenantId, Account) references acc.Accounts(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'usr' and TABLE_NAME=N'Defaults')
create table usr.Defaults
(
	TenantId int not null,
	UserId bigint not null,
	Company bigint,
	Warehouse bigint null,
	RespCenter bigint null,
	PeriodFrom date,
	PeriodTo date,
	constraint PK_Defaults primary key (TenantId, UserId),
	constraint FK_Defaults_UserId_Users foreign key (TenantId, UserId) references appsec.Users(Tenant, Id),
	constraint FK_Defaults_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
	constraint FK_Defaults_Warehouse_Warehouses foreign key (TenantId, Warehouse) references cat.Warehouses(TenantId, Id),
	constraint FK_Defaults_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Settings')
create table app.Settings
(
	TenantId int not null,
	CheckRems nchar(1),
	CheckPayments nchar(1),
	AccPlanRems bigint,
	AccPlanPayments bigint,
	constraint PK_Settings primary key (TenantId),
	constraint FK_Settings_AccPlanRems_Accounts foreign key (TenantId, AccPlanRems) references acc.Accounts(TenantId, Id),
	constraint FK_Settings_AccPlanPayments_Accounts foreign key (TenantId, AccPlanPayments) references acc.Accounts(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Widgets')
create table app.Widgets
(
	TenantId int not null,
	Id bigint not null,
	Kind nvarchar(16),
	[Name] nvarchar(255),
	rowSpan int,
	colSpan int,
	[Url] nvarchar(255),
	Memo nvarchar(255),
	Icon nvarchar(32),
	Params nvarchar(1023),
	constraint PK_Widgets primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'app' and SEQUENCE_NAME = N'SQ_Dashboards')
	create sequence app.SQ_Dashboards as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Dashboards')
create table app.Dashboards
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Dashboards_Id default(next value for app.SQ_Dashboards),
	[User] bigint not null,
	Kind nvarchar(16),
	constraint PK_Dashboards primary key (TenantId, Id),
	constraint FK_Dashboards_User_Users foreign key (TenantId, [User]) references appsec.Users(Tenant, Id),
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'app' and SEQUENCE_NAME = N'SQ_DashboardItems')
	create sequence app.SQ_DashboardItems as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'DashboardItems')
create table app.DashboardItems
(
	TenantId int not null,
	Id bigint not null
		constraint DF_DashboardItems_Id default(next value for app.SQ_DashboardItems),
	Dashboard bigint,
	Widget bigint,
	-- row, col, rowSpan, colSpan are required
	[row] int, 
	[col] int,
	rowSpan int,
	colSpan int,
	Params nvarchar(1023),
	constraint PK_DashboardItems primary key (TenantId, Id),
	constraint FK_DashboardItems_Dashboard_Dashboards foreign key (TenantId, Dashboard) references app.Dashboards(TenantId, Id),
	constraint FK_DashboardItems_Widget_Widgets foreign key (TenantId, Widget) references app.Widgets(TenantId, Id)
);
go
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'IntegrationSources')
create table app.IntegrationSources
(
	Id int not null
		constraint PK_IntegrationSources primary key,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Icon] nvarchar(16),
	[Key] nvarchar(16),
	[Logo] nvarchar(255),
	[SetupUrl] nvarchar(255),
	[DocumentUrl] nvarchar(255),
	[Order] int
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'app' and SEQUENCE_NAME = N'SQ_Integrations')
	create sequence app.SQ_Integrations as bigint start with 100 increment by 1;
go
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Integrations')
create table app.[Integrations]
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Integrations_Id default(next value for app.SQ_Integrations),
	Source int not null,
	Active bit not null
		constraint DF_Integrations_Active default(1),
	[Key] nvarchar(16),
	[Name] nvarchar(255),
	Memo nvarchar(255),
	-- Integration params
	ApiKey nvarchar(255),
	constraint PK_Integrations primary key (TenantId, Id),
	constraint FK_Integrations_Source_IntegrationSources foreign key (Source) references app.IntegrationSources(Id),
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'app' and SEQUENCE_NAME = N'SQ_Notifications')
	create sequence app.SQ_Notifications as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Notifications')
create table app.Notifications
(
	TenantId int not null,
	UserId bigint not null,
	Id bigint not null
		constraint DF_Notifications_Id default(next value for app.SQ_Notifications),
	[Text] nvarchar(255),
	[Icon] nvarchar(32),
	UtcDateCreated datetime not null
		constraint DF_Notifications_UtcDateCreated default(getutcdate()),
	[Done] bit not null
		constraint DF_Notifications_Done default(0),
	[LinkUrl] nvarchar(255) null,
	[Link] bigint null,
	constraint PK_Notifications primary key (TenantId, Id),
	constraint FK_Notifications_UserId_Users foreign key (TenantId, UserId) references appsec.Users(Tenant, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'app' and SEQUENCE_NAME = N'SQ_TaskStates')
	create sequence app.SQ_TaskStates as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'TaskStates')
create table app.TaskStates (
	TenantId int not null,
	[Id] bigint not null
		constraint DF_TaskStates_Id default(next value for crm.SQ_TaskStates),
	Void bit not null 
		constraint DF_TaskStates_Void default(0),
	[Order] int,
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Memo] nvarchar(255),
	constraint PK_TaskStates primary key (TenantId, [Id])
);
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'app' and SEQUENCE_NAME = N'SQ_Tasks')
	create sequence app.SQ_Tasks as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Tasks')
create table app.Tasks
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Tasks_Id default(next value for app.SQ_Tasks),
	[Text] nvarchar(255),
	[State] bigint,
	Assignee bigint null,
	[Notice] nvarchar(255),
	UtcDateCreated datetime not null
		constraint DF_Tasks_UtcDateCreated default(getutcdate()),
	UtcDateComplete datetime not null
		constraint DF_Tasks_UtcDateComplete default(getutcdate()),
	[LinkUrl] nvarchar(255) null,
	[Link] bigint null,
	Project bigint null,
	[Void] bit not null
		constraint DF_Tasks_Void default(0),
	constraint PK_Tasks primary key (TenantId, Id),
	constraint FK_Tasks_State_States foreign key (TenantId, Assignee) references app.TaskStates(TenantId, Id),
	constraint FK_Tasks_Assignee_Users foreign key (TenantId, Assignee) references appsec.Users(Tenant, Id),
	constraint FK_Tasks_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id)
);
go
-- TRIGGERS
------------------------------------------------
create or alter trigger jrn.CashJournal_ITRIG on jrn.CashJournal
  for insert not for replication
as
begin
	set nocount on;
	with T(TenantId, CashAccount, [Sum]) as
	(
		select TenantId, CashAccount, [Sum] = sum([Sum] * InOut) from inserted
		group by TenantId, CashAccount
	)
	merge jrn.CashReminders as t
	using T as s
	on t.TenantId = s.TenantId and t.CashAccount = s.CashAccount
	when matched then update set
		t.[Sum] = t.Sum + s.[Sum]
	when not matched by target then insert
		(TenantId, CashAccount, [Sum]) values
		(TenantId, CashAccount, [Sum]);
end
go
------------------------------------------------
create or alter trigger jrn.CashJournal_DTRIG on jrn.CashJournal
  for delete not for replication
as
begin
	set nocount on;
	with T(TenantId, CashAccount, [SumD]) as
	(
		select TenantId, CashAccount, [SumD] = sum([Sum] * InOut) from deleted
		group by TenantId, CashAccount
	)
	update jrn.CashReminders set [Sum] = [Sum] - T.[SumD]
	from jrn.CashReminders r inner join T on r.TenantId = T.TenantId and r.CashAccount = T.CashAccount
end
go
