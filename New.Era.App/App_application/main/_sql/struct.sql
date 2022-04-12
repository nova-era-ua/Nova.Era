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
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'usr')
	exec sp_executesql N'create schema usr';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'rep')
	exec sp_executesql N'create schema rep';
go
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'ini')
	exec sp_executesql N'create schema ini';
go
------------------------------------------------
grant execute on schema::cat to public;
grant execute on schema::doc to public;
grant execute on schema::acc to public;
grant execute on schema::jrn to public;
grant execute on schema::usr to public;
grant execute on schema::rep to public;
grant execute on schema::ini to public;
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
	[Alpha3] nchar(3),
	[Number3] nchar(3),
	[Char] nchar(1),
	[Denom] int,
	[Name] nvarchar(255) null,
	[Memo] nvarchar(255) null,
		constraint PK_Currencies primary key (TenantId, Id)
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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Warehouses')
	create sequence cat.SQ_Warehouses as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Warehouses')
create table cat.Warehouses
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Warehouses_PK default(next value for cat.SQ_Warehouses),
	Void bit not null 
		constraint DF_Warehouses_Void default(0),
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Warehouses primary key (TenantId, Id)
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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_BankAccounts')
	create sequence cat.SQ_BankAccounts as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'BankAccounts')
create table cat.BankAccounts
(
	TenantId int not null,
	Id bigint not null
		constraint DF_BankAccounts_PK default(next value for cat.SQ_BankAccounts),
	Void bit not null 
		constraint DF_BankAccounts_Void default(0),
	Company bigint not null,
	Currency bigint not null,
	[Name] nvarchar(255),
	[Bank] bigint,
	[AccountNo] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_BankAccounts primary key (TenantId, Id),
		constraint FK_BankAccounts_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_BankAccounts_Bank_Banks foreign key (TenantId, Bank) references cat.Banks(TenantId, Id),
		constraint FK_BankAccounts_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id)
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
		constraint DF_CashAccounts_PK default(next value for cat.SQ_CashAccounts),
	Void bit not null 
		constraint DF_CashAccounts_Void default(0),
	Company bigint not null,
	Currency bigint not null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_CashAccounts primary key (TenantId, Id),
		constraint FK_CashAccounts_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_CashAccounts_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id)
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
	IsItem bit,
	IsAgent bit,
	IsWarehouse bit,
	IsBankAccount bit,
	IsCash bit
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
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Forms primary key (TenantId, Id)
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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_Operations')
	create sequence doc.SQ_Operations as bigint start with 1000 increment by 1;
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
	RowKind nvarchar(16) not null,
	IsIn bit not null,
	IsOut bit not null,
	Factor smallint -- 1 normal, -1 storno
		constraint CK_OpJournalStore_Factor check (Factor in (1, -1)),
		constraint PK_OpJournalStore primary key (TenantId, Id, Operation),
		constraint FK_OpJournalStore_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
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
		constraint DF_SQ_OpTrans_PK default(next value for doc.SQ_OpTrans),
	Operation bigint not null,
	RowNo int,
	RowKind nvarchar(16) not null,
	[Plan] bigint not null,
	Dt bigint null,
	Ct bigint null,
	DtAccMode nchar(1), -- ()Fixed, (I)tem, R(ole)
	DtSum nchar(1), -- ()Sum, (D)iscount, (W)Without discount, (V)at
	DtRow nchar(1), -- ()Sum, (R)ows
	DtWarehouse nchar(1),
	CtAccMode nchar(1),
	CtSum nchar(1),
	CtRow nchar(1),
	CtWarehouse nchar(1),
		constraint PK_OpTrans primary key (TenantId, Id, Operation),
		constraint FK_OpTrans_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id),
		constraint FK_OpTrans_Plan_Accounts foreign key (TenantId, [Plan]) references acc.Accounts(TenantId, Id),
		constraint FK_OpTrans_Dt_Accounts foreign key (TenantId, [Dt]) references acc.Accounts(TenantId, Id),
		constraint FK_OpTrans_Ct_Accounts foreign key (TenantId, [Ct]) references acc.Accounts(TenantId, Id)
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
	WhFrom bigint null,
	WhTo bigint  null,
	Memo nvarchar(255),
	DateApplied datetime,
	UserCreated bigint not null,
	UtcDateCreated datetime not null 
		constraint DF_Documents_UtcDateCreated default(getutcdate()),
	constraint PK_Documents primary key (TenantId, Id),
	constraint FK_Documents_Operation_Operations foreign key (TenantId, [Operation]) references doc.Operations(TenantId, Id),
	constraint FK_Documents_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
	constraint FK_Documents_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
	constraint FK_Documents_WhFrom_Warehouses foreign key (TenantId, WhFrom) references cat.Warehouses(TenantId, Id),
	constraint FK_Documents_WhTo_Warehouses foreign key (TenantId, WhTo) references cat.Warehouses(TenantId, Id),
	constraint FK_Documents_UserCreated_Users foreign key (TenantId, UserCreated) references appsec.Users(Tenant, Id)
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
	Warehouse bigint null,
	Item bigint null,
	Dir smallint not null,
	Qty float null
		constraint DF_StockJournal_Qty default(0),
	[Sum] money not null
		constraint DF_StockJournal_Sum default(0),
		constraint PK_StockJournal primary key (TenantId, Id),
		constraint FK_StockJournal_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_StockJournal_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
		constraint FK_StockJournal_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_StockJournal_Warehouse_Warehouses foreign key (TenantId, Warehouse) references cat.Warehouses(TenantId, Id)
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
		constraint DF_Journal_PK default(next value for jrn.SQ_Journal),
	TrNo int not null,
	RowNo int,
	[Date] datetime,
	Document bigint,
	Detail bigint,
	DtCt smallint not null,
	Account bigint not null,
	CorrAccount bigint not null,
	Company bigint null,
	Warehouse bigint null,
	Agent bigint null,
	Item bigint null,
	BankAccount bigint null,
	CashAccount bigint null,
	Qty float null,
	[Sum] money not null
		constraint DF_Journal_Sum default(0),
		constraint PK_Journal primary key (TenantId, Id),
		constraint FK_Journal_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
		constraint FK_Journal_Account_Accounts foreign key (TenantId, Account) references acc.Accounts(TenantId, Id),
		constraint FK_Journal_CorrAccount_Accounts foreign key (TenantId, CorrAccount) references acc.Accounts(TenantId, Id),
		constraint FK_Journal_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
		constraint FK_Journal_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_Journal_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
		constraint FK_Journal_Warehouse_Warehouses foreign key (TenantId, Warehouse) references cat.Warehouses(TenantId, Id),
		constraint FK_Journal_BankAccount_BankAccounts foreign key (TenantId, BankAccount) references cat.BankAccounts(TenantId, Id),
		constraint FK_Journal_BankAccount_CashAccounts foreign key (TenantId, CashAccount) references cat.CashAccounts(TenantId, Id)
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
		constraint DF_Reports_PK default(next value for rep.SQ_Reports),
	Void bit not null 
		constraint DF_Reports_Void default(0),
	Account bigint,
	[Menu] nvarchar(32),
	[Name] nvarchar(255),
	[Url] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Reports primary key (TenantId, Id),
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
	PeriodFrom date,
	PeriodTo date,
		constraint PK_Defaults primary key (TenantId, UserId),
		constraint FK_Defaults_UserId_Users foreign key (TenantId, UserId) references appsec.Users(Tenant, Id),
		constraint FK_Defaults_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_Defaults_Warehouse_Warehouses foreign key (TenantId, Warehouse) references cat.Warehouses(TenantId, Id)
);
go

