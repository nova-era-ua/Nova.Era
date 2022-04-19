/*
version: 10.1.1012
generated: 19.04.2022 10:26:15
*/


/* SqlScripts/application.sql */

-- security schema (common)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'appsec')
	exec sp_executesql N'create schema appsec';
go
grant execute on schema::appsec to public;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'appsec' and SEQUENCE_NAME=N'SQ_Tenants')
	create sequence appsec.SQ_Tenants as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'appsec' and TABLE_NAME=N'Tenants')
begin
	create table appsec.Tenants
	(
		Id	int not null constraint PK_Tenants primary key
			constraint DF_Tenants_PK default(next value for appsec.SQ_Tenants),
		[Admin] bigint null, -- admin user ID
		[Source] nvarchar(255) null,
		[TransactionCount] bigint not null constraint DF_Tenants_TransactionCount default(0),
		LastTransactionDate datetime null,
		UtcDateCreated datetime not null constraint DF_Tenants_UtcDateCreated default(getutcdate()),
		TrialPeriodExpired datetime null,
		DataSize float null,
		[State] nvarchar(128) null,
		UserSince datetime null,
		LastPaymentDate datetime null,
		[Locale] nvarchar(32) not null constraint DF_Tenants_Locale default('uk-UA')
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'appsec' and SEQUENCE_NAME=N'SQ_Users')
	create sequence appsec.SQ_Users as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'appsec' and TABLE_NAME=N'Users')
create table appsec.Users
(
	Id	bigint not null
		constraint DF_Users_PK default(next value for appsec.SQ_Users),
	Tenant int not null 
		constraint FK_Users_Tenant_Tenants foreign key references appsec.Tenants(Id),
	UserName nvarchar(255) not null constraint UNQ_Users_UserName unique,
	DomainUser nvarchar(255) null,
	Void bit not null constraint DF_Users_Void default(0),
	SecurityStamp nvarchar(max) not null,
	PasswordHash nvarchar(max) null,
	/*for .net core compatibility*/
	SecurityStamp2 nvarchar(max) null,
	PasswordHash2 nvarchar(max) null,
	TwoFactorEnabled bit not null constraint DF_Users_TwoFactorEnabled default(0),
	Email nvarchar(255) null,
	EmailConfirmed bit not null constraint DF_Users_EmailConfirmed default(0),
	PhoneNumber nvarchar(255) null,
	PhoneNumberConfirmed bit not null constraint DF_Users_PhoneNumberConfirmed default(0),
	LockoutEnabled	bit	not null constraint DF_Users_LockoutEnabled default(1),
	LockoutEndDateUtc datetimeoffset null,
	AccessFailedCount int not null constraint DF_Users_AccessFailedCount default(0),
	[Locale] nvarchar(32) not null constraint DF_Users_Locale2 default('uk-UA'),
	PersonName nvarchar(255) null,
	LastLoginDate datetime null, /*UTC*/
	LastLoginHost nvarchar(255) null,
	Memo nvarchar(255) null,
	ChangePasswordEnabled bit not null constraint DF_Users_ChangePasswordEnabled default(1),
	RegisterHost nvarchar(255) null,
	Segment nvarchar(32) null,
	UtcDateCreated datetime not null constraint DF_Users_UtcDateCreated default(getutcdate()),
	constraint PK_Users primary key (Tenant, Id)
);
go
------------------------------------------------
create or alter view appsec.ViewUsers
as
	select Id, UserName, DomainUser, PasswordHash, SecurityStamp, Email, PhoneNumber,
		LockoutEnabled, AccessFailedCount, LockoutEndDateUtc, TwoFactorEnabled, [Locale],
		PersonName, Memo, Void, LastLoginDate, LastLoginHost, Tenant, EmailConfirmed,
		PhoneNumberConfirmed, RegisterHost, ChangePasswordEnabled, Segment,
		SecurityStamp2, PasswordHash2
	from appsec.Users u
	where Void=0 and Id <> 0;
go
create or alter procedure appsec.FindUserById
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select * from appsec.ViewUsers where Id=@Id;
end
go
------------------------------------------------
create or alter procedure appsec.FindUserByEmail
@Email nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select * from appsec.ViewUsers where Email=@Email;
end
go
------------------------------------------------
create or alter procedure appsec.FindUserByName
@UserName nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select * from appsec.ViewUsers where UserName=@UserName;
end
go
------------------------------------------------
create or alter procedure appsec.FindUserByPhoneNumber
@PhoneNumber nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select * from appsec.ViewUsers where PhoneNumber=@PhoneNumber;
end
go
------------------------------------------------
create or alter procedure appsec.UpdateUserLogin
@Id bigint,
@LastLoginDate datetime,
@LastLoginHost nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update appsec.ViewUsers set LastLoginDate = @LastLoginDate, LastLoginHost = @LastLoginHost 
	where Id=@Id;
end
go
------------------------------------------------
create or alter procedure appsec.UpdateUserLockout
@Id bigint,
@AccessFailedCount int,
@LockoutEndDateUtc datetimeoffset
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update appsec.ViewUsers set 
		AccessFailedCount = @AccessFailedCount, LockoutEndDateUtc = @LockoutEndDateUtc
	where Id=@Id;
end
go
------------------------------------------------
create or alter procedure appsec.UpdateUserPassword
@Id bigint,
@PasswordHash nvarchar(max),
@SecurityStamp nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update appsec.ViewUsers set PasswordHash = @PasswordHash, SecurityStamp = @SecurityStamp where Id=@Id;
end
go
------------------------------------------------
create or alter procedure appsec.GetUserGroups
@UserId bigint
as
begin
	set nocount on;
	-- do nothing
end
go
------------------------------------------------
-- TODO: move to securitySchema
------------------------------------------------
create or alter procedure a2security.[User.ChangePassword.Load]
	@TenantId int = 0,
	@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	if 1 <> (select ChangePasswordEnabled from appsec.Users where Id=@UserId)
	begin
		raiserror (N'UI:@[ChangePasswordDisabled]', 16, -1) with nowait;
	end
	select [User!TUser!Object] = null, [Id!!Id] = Id, [Name!!Name] = UserName, 
		[OldPassword] = cast(null as nvarchar(255)),
		[NewPassword] = cast(null as nvarchar(255)),
		[ConfirmPassword] = cast(null as nvarchar(255)) 
	from appsec.Users where Id=@UserId;
end
go



-- security schema
------------------------------------------------
create or alter procedure a2security.SetTenantId
@TenantId int
as
begin
	set nocount on;
	update appsec.Tenants set TransactionCount = TransactionCount + 1, LastTransactionDate = getutcdate() where Id = @TenantId;
	exec sp_set_session_context @key=N'TenantId', @value=@TenantId, @read_only=0;
end
go
------------------------------------------------
create or alter procedure appsec.CreateTenantUser
@Id bigint,
@UserName nvarchar(255),
@Tenant int,
@PersonName nvarchar(255),
@RegisterHost nvarchar(255) = null,
@PhoneNumber nvarchar(255) = null,
@Memo nvarchar(255) = null,
@TariffPlan nvarchar(255) = null,
@TenantRoles nvarchar(max) = null,
@Locale nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	if not exists(select * from appsec.Tenants where Id = @Tenant)
	begin
		declare @sql nvarchar(255);
		declare @prms nvarchar(255);

		if exists(select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = N'appsec' and ROUTINE_NAME=N'OnCreateTenant')
		begin
			set @sql = N'appsec.OnCreateTenant @TenantId';
			set @prms = N'@TenantId int';
		end

		begin tran;

		insert into appsec.Tenants(Id, [Admin], Locale) values (@Tenant, @Id, @Locale);

		insert into appsec.Users(Tenant, Id, UserName, PersonName, RegisterHost, PhoneNumber, Memo, Locale, 
				SecurityStamp, PasswordHash) 
			values(@Tenant, @Id, @UserName, @PersonName, @RegisterHost, @PhoneNumber, @Memo, @Locale, 
				N'', N'');
		/* system user */
		insert into appsec.Users(Tenant, Id, UserName, SecurityStamp, PasswordHash) values 
			(@Tenant, 0, N'System_' + cast(@Tenant as nvarchar(16)), N'', N'');

		if @sql is not null
			exec sp_executesql @sql, @prms, @Tenant;

		commit tran;
	end
	else
	begin
		-- add new user to current tenant
		begin tran
		-- inherit RegisterHost, TariffPlan, Locale
		declare @TenantLocale nvarchar(32);

		select @RegisterHost = RegisterHost, @TenantLocale=t.Locale 
		from appsec.Tenants t inner join appsec.Users u on t.[Admin] = u.Id
		where t.Id = @Tenant;

		insert into appsec.Users(Tenant, Id, UserName, PersonName, RegisterHost, PhoneNumber, Memo, Locale, 
				SecurityStamp, PasswordHash) 
			values(@Tenant, @Id, @UserName, @PersonName, @RegisterHost, @PhoneNumber, @Memo, isnull(@Locale, @TenantLocale),
				N'', N'');
		commit tran;
	end
end
go

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
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'ui')
	exec sp_executesql N'create schema ui';
go
------------------------------------------------
grant execute on schema::cat to public;
grant execute on schema::doc to public;
grant execute on schema::acc to public;
grant execute on schema::jrn to public;
grant execute on schema::usr to public;
grant execute on schema::rep to public;
grant execute on schema::ini to public;
grant execute on schema::ui to public;
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
	IsCashAccount bit not null,
	Company bigint not null,
	Currency bigint not null,
	[Name] nvarchar(255),
	[Bank] bigint,
	[AccountNo] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_CashAccounts primary key (TenantId, Id),
		constraint FK_CashAccounts_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
		constraint FK_CashAccounts_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id),
		constraint FK_CashAccounts_Bank_Banks foreign key (TenantId, Bank) references cat.Banks(TenantId, Id),
);
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
		constraint DF_Accounts_PK default(next value for acc.SQ_Accounts),
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
	[Uid] uniqueidentifier not null
		constraint DF_Accounts_Uid default(newid()),
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
	[Order] int,
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
	Void bit not null 
		constraint DF_Operations_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Agent] nchar(1),
	Form nvarchar(16) not null,
	[WarehouseFrom] nchar(1),
	[WarehouseTo] nchar(1),
	[Uid] uniqueidentifier not null
		constraint DF_Operations_Uid default(newid()),
	constraint PK_Operations primary key (TenantId, Id),
	constraint FK_Operations_Form_Forms foreign key (TenantId, Form) references doc.Forms(TenantId, Id)
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
	[Uid] uniqueidentifier not null
		constraint DF_OpTrans_Uid default(newid()),
	constraint PK_OpTrans primary key (TenantId, Id, Operation),
	constraint FK_OpTrans_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id),
	constraint FK_OpTrans_Plan_Accounts foreign key (TenantId, [Plan]) references acc.Accounts(TenantId, Id),
	constraint FK_OpTrans_Dt_Accounts foreign key (TenantId, [Dt]) references acc.Accounts(TenantId, Id),
	constraint FK_OpTrans_Ct_Accounts foreign key (TenantId, [Ct]) references acc.Accounts(TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'ui' and TABLE_NAME=N'OpMenuLinks')
create table ui.OpMenuLinks
(
	TenantId int not null,
	Operation bigint not null,
	Menu nvarchar(32) not null,
	[Uid] uniqueidentifier not null
		constraint DF_OpMenuLinks_Uid default(newid()),
	constraint PK_OpMenuLinks primary key (TenantId, Operation, Menu),
	constraint FK_OpMenuLinks_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
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
		constraint DF_Documents_PK default(next value for doc.SQ_Documents),
	[Date] datetime,
	Operation bigint not null,
	[Sum] money not null
		constraint DF_Documents_Sum default(0),
	Done bit not null
		constraint DF_Documents_Done default(0),
	Company bigint null,
	Agent bigint null,
	Currency bigint null,
	WhFrom bigint null,
	WhTo bigint  null,
	CashAccFrom bigint null,
	CashAccTo bigint null,
	Memo nvarchar(255),
	DateApplied datetime,
	UserCreated bigint not null,
	UtcDateCreated datetime not null 
		constraint DF_Documents_UtcDateCreated default(getutcdate()),
	constraint PK_Documents primary key (TenantId, Id),
	constraint FK_Documents_Operation_Operations foreign key (TenantId, [Operation]) references doc.Operations(TenantId, Id),
	constraint FK_Documents_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
	constraint FK_Documents_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
	constraint FK_Documents_Currency_Currencies foreign key (TenantId, Currency) references cat.Currencies(TenantId, Id),
	constraint FK_Documents_WhFrom_Warehouses foreign key (TenantId, WhFrom) references cat.Warehouses(TenantId, Id),
	constraint FK_Documents_WhTo_Warehouses foreign key (TenantId, WhTo) references cat.Warehouses(TenantId, Id),
	constraint FK_Documents_CashAccFrom_CashAccounts foreign key (TenantId, CashAccFrom) references cat.CashAccounts(TenantId, Id),
	constraint FK_Documents_CashAccTo_CashAccounts foreign key (TenantId, CashAccTo) references cat.CashAccounts(TenantId, Id),
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
	[Plan] bigint not null,
	Account bigint not null,
	CorrAccount bigint not null,
	Company bigint null,
	Warehouse bigint null,
	Agent bigint null,
	Item bigint null,
	CashAccount bigint null,
	Qty float null,
	[Sum] money not null
		constraint DF_Journal_Sum default(0),
	constraint PK_Journal primary key (TenantId, Id),
	constraint FK_Journal_Document_Documents foreign key (TenantId, Document) references doc.Documents(TenantId, Id),
	constraint FK_Journal_Plan_Accounts foreign key (TenantId, [Plan]) references acc.Accounts(TenantId, Id),
	constraint FK_Journal_Account_Accounts foreign key (TenantId, Account) references acc.Accounts(TenantId, Id),
	constraint FK_Journal_CorrAccount_Accounts foreign key (TenantId, CorrAccount) references acc.Accounts(TenantId, Id),
	constraint FK_Journal_Detail_DocDetails foreign key (TenantId, Detail) references doc.DocDetails(TenantId, Id),
	constraint FK_Journal_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
	constraint FK_Journal_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id),
	constraint FK_Journal_Warehouse_Warehouses foreign key (TenantId, Warehouse) references cat.Warehouses(TenantId, Id),
	constraint FK_Journal_CashAccount_CashAccounts foreign key (TenantId, CashAccount) references cat.CashAccounts(TenantId, Id)
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
		constraint DF_Reports_PK default(next value for rep.SQ_Reports),
	Void bit not null 
		constraint DF_Reports_Void default(0),
	[Type] nvarchar(16) not null,
	[File] nvarchar(16),
	Account bigint,
	[Menu] nvarchar(32),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
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
	PeriodFrom date,
	PeriodTo date,
	constraint PK_Defaults primary key (TenantId, UserId),
	constraint FK_Defaults_UserId_Users foreign key (TenantId, UserId) references appsec.Users(Tenant, Id),
	constraint FK_Defaults_Company_Companies foreign key (TenantId, Company) references cat.Companies(TenantId, Id),
	constraint FK_Defaults_Warehouse_Warehouses foreign key (TenantId, Warehouse) references cat.Warehouses(TenantId, Id)
);
go


-- MIGRATIONS

if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Currencies' and COLUMN_NAME=N'Symbol')
begin
	alter table cat.Currencies add Symbol nvarchar(3);
	alter table cat.Currencies drop column [Char];
end
go

/*
common
*/
------------------------------------------------
create or alter function cat.fn_GetAgentName(@TenantId int, @Id bigint)
returns nvarchar(255)
as
begin
	declare @name nvarchar(255);
	if @Id is not null and @Id <> -1
		select @name = [Name] from cat.Agents where TenantId=@TenantId and Id=@Id;
	return @name;
end
go
------------------------------------------------
create or alter function cat.fn_GetWarehouseName(@TenantId int, @Id bigint)
returns nvarchar(255)
as
begin
	declare @name nvarchar(255);
	if @Id is not null and @Id <> -1
		select @name = [Name] from cat.Warehouses where TenantId=@TenantId and Id=@Id;
	return @name;
end
go
------------------------------------------------
create or alter function cat.fn_GetCompanyName(@TenantId int, @Id bigint)
returns nvarchar(255)
as
begin
	declare @name nvarchar(255);
	if @Id is not null and @Id <> -1
		select @name = [Name] from cat.Companies where TenantId=@TenantId and Id=@Id;
	return @name;
end
go
------------------------------------------------
create or alter function cat.fn_GetCashAccountName(@TenantId int, @Id bigint)
returns nvarchar(255)
as
begin
	declare @name nvarchar(255);
	if @Id is not null
		select @name = isnull([Name], AccountNo) from cat.CashAccounts where TenantId=@TenantId and Id=@Id;
	return @name;
end
go
------------------------------------------------
create or alter function a2sys.fn_GetCurrentTenant(@TenantId int)
returns int
as
begin
	set @TenantId = isnull(cast(session_context(N'TenantId') as int), 1);
	return @TenantId;
end
go

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
	insert into a2sys.SysParams ([Name], StringValue) values (N'AppTitle', N'Nova.Era');
else
	update a2sys.SysParams set StringValue = N'Nova.Era' where [Name] = N'AppTitle';
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
		(88,    1,  88, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
		(90,    1,  90, N'@[Profile]',        N'profile',   N'user', null),
		-- CRM
		--(1101,  11, 11, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		--(1102,  11, 12, N'@[Leads]',          N'lead',      N'users', N'border-top'),
		-- Sales
		(1201,   12, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(120,    12, 11, N'@[Documents]',      null,  null, null),
		(1202,   120, 2, N'@[Orders]',         N'order',     N'task-complete', null),
		(1203,   120, 3, N'@[Sales]',          N'sales',     N'shopping', null),
		(1204,   120, 4, N'@[Payment]',        N'payment',   N'currency-uah', null),
		(122,    12, 12, N'@[Catalogs]',      null,  null, null),
		(1220,   122, 30, N'@[Customers]',      N'agent',     N'users', null),
		(1221,   122, 31, N'@[Items]',          N'item',      N'package-outline', null),
		(1222,   122, 32, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1230,   12, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1231,   12, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Purchase
		(1301,   13, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(130,    13, 11, N'@[Documents]',      null,  null, null),
		(1302,  130, 10, N'@[Purchases]',      N'purchase',  N'cart', null),
		(1303,  130, 11, N'@[Warehouse]',      N'stock',     N'warehouse', null),
		(1304,  130, 12, N'@[Payment]',        N'payment',   N'currency-uah', null),
		--(1310,   13, 20, N'@[Planning]',       N'plan',      N'calendar', N'border-top'),
		--(1311,   13, 21, N'@[Prices]',         N'price',     N'chart-column', N'border-top'),
		(133,    13, 14, N'@[Catalogs]',  null, null, null),
		(1320,  133, 10, N'@[Suppliers]',      N'agent',     N'users', null),
		(1321,  133, 11, N'@[Items]',          N'item',      N'package-outline', null),
		(1322,  133, 12, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1330,   13, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1331,   13, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Accounting
		(1501,   15, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(150,    15, 11, N'@[Documents]',      null, null, null),
		(1502,  150, 10, N'@[Bank]',           N'bank',   N'bank',  null),
		(1503,  150, 11, N'@[CashAccount]',    N'cash',   N'currency-uah',  null),
		(1504,   15, 12, N'@[AccountPlans]',   N'plan',      N'account',  N'border-top'),
		(153,    15, 13, N'@[Catalogs]',  null, null, null),
		(1505,  153, 10, N'@[Agents]',         N'agent',     N'users',  null),
		(1506,  153, 11, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1507,   15, 15, N'@[Journal]',        N'journal',   N'file-content',  N'border-top'),
		(1530,   15, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1531,   15, 41, N'@[Service]',        N'service',   N'gear-outline', null),

		-- Settings
		(880,   88, 10, N'@[Catalogs]',     null, null, null),
		(8811, 880, 11, N'@[Companies]',    N'company',   N'company', null),
		(8812, 880, 12, N'@[Warehouses]',   N'warehouse', N'warehouse', null),
		(8813, 880, 13, N'@[BankAccounts]', N'bankacc',   N'bank', null),
		(8814, 880, 14, N'@[CashAccounts]', N'cashacc',   N'currency-uah', null),
		(8815, 880, 15, N'@[Agents]',       N'agent',     N'users', null),
		(8816, 880, 16, N'@[Items]',        N'item',      N'package-outline', null),
		(8817, 880, 16, N'@[CatalogOther]', N'catalog',   N'list', null),
		(881,   88, 11, N'@[Settings]',     null, null, null),
		(8820, 881, 17, N'@[AccountPlans]', N'accountplan', N'account',  null),
		(8821, 881, 18, N'@[Operations]',   N'operation',   N'file-content', null),
		(882,   88, 12, N'@[Administration]', null, null, null),
		(8830, 882, 16, N'@[Users]',        N'user',    N'user',  null),
		(8850,  88, 20, N'Розробка (debug)',N'develop',   N'switch', N'border-top'),
		-- Profile
		(9001,  90, 10, N'@[Defaults]',    N'default',   N'list', null);

	exec a2ui.[MenuModule.Merge] @menu, 1, 9999;
end
go
-------------------------------------------------
-- Catalog
begin
	set nocount on;
	declare @cat table(Id int, Menu nvarchar(16), [Name] nvarchar(255), 
		[Order] int, Category nvarchar(32), [Memo] nvarchar(255), [Url] nvarchar(255), Icon nvarchar(16));
	insert into @cat (Id, Menu, [Order], [Category], [Name], [Url], Icon, Memo) values
	(100, N'Sales', 10, N'@[Items]', N'@[Units]',    N'/catalog/unit/index', N'list',  N''),
	--(101, N'Sales', 11, N'@[Items]', N'@[Vendors]',  N'/catalog/vendor/index', N'list',  N''),
	--(102, N'Sales', 12, N'@[Items]', N'@[Brands]',   N'/catalog/brand/index', N'list',  N''),

	(200, N'Purchase',   10, N'@[Items]',  N'@[Units]',      N'/catalog/unit/index', N'list',  N''),
	(201, N'Purchase',   11, N'@[Items]',  N'@[PriceLists]', N'/catalog/pricelist/index', N'list',  N''),
	-- accounting
	(300, N'Accounting', 10, N'@[Accounting]', N'@[Banks]', N'/catalog/bank/index', N'list',  N''),
	(301, N'Accounting', 11, N'@[Accounting]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N''),
	-- settings
	(900, N'Settings',  10, N'@[Accounting]', N'@[Banks]', N'/catalog/bank/index', N'list',  N''),
	(901, N'Settings',  11, N'@[Accounting]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N''),
	(902, N'Settings',  12, N'@[Items]',  N'@[Units]',      N'/catalog/unit/index', N'list',  N''),
	(903, N'Settings',  13, N'@[Items]',  N'@[PriceLists]', N'/catalog/pricelist/index', N'list',  N'');

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

/* Profile.Default */
------------------------------------------------
create or alter procedure usr.[Default.Load]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Default!TDefault!Object] = null,
		[Company.Id!TCompany!Id] = d.Company, [Company.Name!TCompany!Name] = c.[Name],
		[Warehouse.Id!TWarehouse!Id] = d.Warehouse, [Warehouse.Name!TWarehouse!Name] = w.[Name],
		[Period.From!TPeriod!] = isnull(d.PeriodFrom, getdate()), [Period.To!TPeriod!] = isnull(d.PeriodTo, getdate())
	from usr.Defaults d
		left join cat.Companies c on d.TenantId = c.TenantId and d.Company = c.Id
		left join cat.Warehouses w on d.TenantId = w.TenantId and d.Warehouse = w.Id
	where d.TenantId = @TenantId and d.UserId = @UserId;
end
go
------------------------------------------------
create or alter procedure usr.[Default.Ensure] 
@TenantId int = 1, 
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	if not exists(select * from usr.Defaults where TenantId = @TenantId and UserId = @UserId)
		insert into usr.Defaults(TenantId, UserId) values (@TenantId, @UserId);
end
go
------------------------------------------------
create or alter procedure usr.[Default.SetCompany]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	exec usr.[Default.Ensure] @TenantId = @TenantId, @UserId = @UserId;
	update usr.Defaults set Company = @Id where TenantId = @TenantId and UserId = @UserId;
end
go
------------------------------------------------
create or alter procedure usr.[Default.SetWarehouse]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	exec usr.[Default.Ensure] @TenantId = @TenantId, @UserId = @UserId;
	update usr.Defaults set Warehouse = @Id where TenantId = @TenantId and UserId = @UserId;
end
go
------------------------------------------------
create or alter procedure usr.[Default.SetPeriod]
@TenantId int = 1,
@UserId bigint,
@From date,
@To date
as
begin
	set nocount on;
	set transaction isolation level read committed;

	exec usr.[Default.Ensure] @TenantId = @TenantId, @UserId = @UserId;
	update usr.Defaults set PeriodFrom = @From, PeriodTo=@To where TenantId = @TenantId and UserId = @UserId;
end
go
------------------------------------------------
create or alter procedure usr.[Default.GetUserPeriod]
@TenantId int = 1,
@UserId bigint,
@From date output,
@To date output
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	if @From is not null and @To is not null
		return;
	exec usr.[Default.Ensure] @TenantId = @TenantId, @UserId = @UserId;
	select @From = [PeriodFrom], @To = [PeriodTo] from usr.Defaults where TenantId = @TenantId and UserId = @UserId;
	if @From is null or @To is null
	begin
		update usr.Defaults set PeriodFrom = getdate(), PeriodTo = getdate() where TenantId = @TenantId and UserId = @UserId;
		select @From = [PeriodFrom], @To = [PeriodTo] from usr.Defaults where TenantId = @TenantId and UserId = @UserId;
	end
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

-- Warehouse
------------------------------------------------
create or alter procedure cat.[Warehouse.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Warehouses!TWarehouse!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo
	from cat.Warehouses c
	where c.TenantId = @TenantId; 
end
go
------------------------------------------------
create or alter procedure cat.[Warehouse.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Warehouse!TWarehouse!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo
	from cat.Warehouses c
	where c.TenantId = @TenantId and c.Id = @Id;
end
go
-------------------------------------------------
drop procedure if exists cat.[Warehouse.Metadata];
drop procedure if exists cat.[Warehouse.Update];
drop type if exists cat.[Warehouse.TableType];
go
-------------------------------------------------
create type cat.[Warehouse.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Warehouse.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Warehouse cat.[Warehouse.TableType];
	select [Warehouse!Warehouse!Metadata] = null, * from @Warehouse;
end
go
------------------------------------------------
create or alter procedure cat.[Warehouse.Update]
@TenantId int = 1,
@UserId bigint,
@Warehouse cat.[Warehouse.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Warehouses as t
	using @Warehouse as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, s.[Name], s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Warehouse.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

/* Item */
-------------------------------------------------
create or alter view cat.[view_Items]
as
select [Id!!Id] = i.Id, 
	[Name!!Name] = i.[Name], i.FullName, i.Article, i.Memo,
	[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
	[!TenantId] = i.TenantId
from cat.Items i
	left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
go
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
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
		[ParentFolder.Id!TParentFolder!Id] = iti.Parent, [ParentFolder.Name!TParentFolder!Name] = it.[Name]
	from cat.Items i 
		inner join cat.ItemTreeItems iti on iti.Item = i.Id and iti.TenantId = i.TenantId
		inner join cat.ItemTree it on iti.Parent = it.Parent and iti.TenantId = it.TenantId
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
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
		[ParentFolder.Id!TParentFolder!Id] = T.Parent, [ParentFolder.Name!TParentFolder!Name] = tr.[Name],
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
		[!!RowCount]  = (select count(1) from T)
	from T inner join cat.Items i on T.Id = i.Id and i.TenantId = @TenantId
		inner join cat.ItemTree tr on T.Parent = tr.Id and tr.TenantId = @TenantId
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
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
-------------------------------------------------
create or alter procedure cat.[Item.Plain.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);
	
	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';


	declare @items table(rowno int identity(1, 1), id bigint, unit bigint, rowcnt int);

	insert into @items(id, unit, rowcnt)
	select i.Id, i.Unit, 
		count(*) over()
	from cat.Items i
	where i.TenantId = @TenantId
		and (@fr is null or i.Name like @fr or i.FullName like @fr or i.Memo like @fr or i.Article like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'id' then i.[Id]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then i.[Name]
				when N'fullname' then i.[FullName]
				when N'article' then i.[Article]
				when N'memo' then i.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then i.[Id]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then i.[Name]
				when N'fullname' then i.[FullName]
				when N'article' then i.[Article]
				when N'memo' then i.[Memo]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Items!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.FullName, i.Article, i.Memo,
		i.IsStock,
		[Unit!TUnit!RefId] = i.Unit,
		[!!RowCount] = t.rowcnt
	from @items t inner join cat.Items i on i.TenantId = @TenantId and t.id = i.Id
	order by t.rowno;

	-- maps
	with T as (select unit from @items group by unit)
	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.[Short]
	from cat.Units u 
		inner join T t on u.TenantId = @TenantId and u.Id = unit;

	-- filter
	select [!$System!] = null, [!Items!Offset] = @Offset, [!Items!PageSize] = @PageSize, 
		[!Items!SortOrder] = @Order, [!Items!SortDir] = @Dir,
		[!Items.Fragment!Filter] = @Fragment;
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
	[Name] nvarchar(255),
	Article nvarchar(32),
	FullName nvarchar(255),
	[Memo] nvarchar(255),
	IsStock bit,
	Unit bigint
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
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short
	from cat.Items i 
		left join cat.Units u on  i.TenantId = u.TenantId and i.Unit = u.Id
	where i.TenantId = @TenantId and i.Id=@Id and i.Void = 0;
	
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
			t.IsStock = s.IsStock,
			t.Unit = s.Unit
	when not matched by target then 
		insert (TenantId, [Name], FullName, [Article], Memo, IsStock, Unit)
		values (@TenantId, s.[Name], s.FullName, s.Article, s.Memo, s.IsStock, s.Unit)
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

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
		select tr.Id, tr.Parent, [Level] + 1 
			from cat.ItemTree tr inner join T on tr.Id = T.Parent and tr.TenantId = @TenantId
		where tr.Id <> @Root
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
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Items!TItem!Array] = null, *
	from cat.view_Items v
	where v.[!TenantId] = @TenantId
	order by v.[Id!!Id]
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Find.Article]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select top(1) [Item!TItem!Object] = null, *
	from cat.view_Items v
	where v.[!TenantId] = @TenantId and v.Article = @Text;
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

/* BANK */
------------------------------------------------
create or alter procedure cat.[Bank.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + upper(@Fragment) + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	with T(Id, [RowCount], RowNo) as (
	select b.Id, count(*) over (),
		RowNo = row_number() over (order by 
		case when @Dir = N'asc' then
			case @Order
				when N'code' then b.[Code]
				when N'bankcode' then b.[BankCode]
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'code' then b.[Code]
				when N'bankcode' then b.[BankCode]
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then b.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then b.[Id]
			end
		end desc,
		b.Id
		)
	from cat.Banks b
	where TenantId = @TenantId and (@fr is null or b.BankCode like @fr or b.Code like @fr 
		or b.[Name] like @fr or b.FullName like @fr or b.Memo like @fr)
	)
	select [Banks!TBank!Array] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.FullName, 
		b.Code, b.BankCode, b.Memo,
		[!!RowCount] = t.[RowCount]
	from cat.Banks b
	inner join T t on t.Id = b.Id
	order by t.RowNo
	offset @Offset rows fetch next @PageSize rows only 
	option(recompile);

	select [!$System!] = null, [!Banks!Offset] = @Offset, [!Banks!PageSize] = @PageSize, 
		[!Banks!SortOrder] = @Order, [!Banks!SortDir] = @Dir,
		[!Banks.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Bank.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Bank!TBank!Object] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo, b.[Code], b.FullName, b.BankCode
	from cat.Banks b
	where TenantId = @TenantId and b.Id = @Id;
end
go
---------------------------------------------
drop procedure if exists cat.[Bank.Upload.Metadata];
drop procedure if exists cat.[Bank.Upload.Update];
drop procedure if exists cat.[Bank.Metadata];
drop procedure if exists cat.[Bank.Update];
drop type if exists cat.[Bank.Upload.TableType];
drop type if exists cat.[Bank.TableType];
go
---------------------------------------------
create type cat.[Bank.Upload.TableType] as table
(
	Id bigint,
	[GLMFO] nvarchar(255),
	[SHORTNAME] nvarchar(255),
	[FULLNAME] nvarchar(255),
	[KOD_EDRPOU] nvarchar(50)
)
go
------------------------------------------------
create type cat.[Bank.TableType] as table
(
	Id bigint,
	[Code] nvarchar(16),
	[BankCode] nvarchar(16),
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[Bank.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Bank cat.[Bank.TableType];
	select [Bank!Bank!Metadata] = null, * from @Bank;
end
go
---------------------------------------------
create or alter procedure cat.[Bank.Update]
@TenantId int = 1,
@UserId bigint,
@Bank cat.[Bank.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Banks as t
	using @Bank as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[BankCode] = s.[BankCode],
		t.[FullName] = s.[FullName], 
		t.[Code] = s.[Code]
	when not matched by target then insert
		(TenantId, [Name], Memo, BankCode, FullName, Code) values
		(@TenantId, [Name], Memo, BankCode, FullName, Code)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Bank.Load] @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Bank.Upload.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Banks cat.[Bank.Upload.TableType];
	select [Banks!Banks!Metadata] = null, * from @Banks;
end
go

---------------------------------------------
create or alter procedure cat.[Bank.Upload.Update]
@TenantId int = 1,
@UserId bigint,
@Banks cat.[Bank.Upload.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	set @TenantId= a2sys.fn_GetCurrentTenant(@TenantId);

	merge cat.Banks as t
	using @Banks as s
	on t.TenantId = @TenantId and t.BankCode = s.[GLMFO]
	when matched then update set
		t.BankCode = s.[GLMFO],
		t.[Name] =  s.[SHORTNAME],
		t.[Code] = s.KOD_EDRPOU,
		t.[FullName] = s.FULLNAME,
		t.Void = 0
	when not matched by target then insert
		(TenantId, BankCode, [Name], [Code], [FullName]) values
		(@TenantId, s.[GLMFO], [SHORTNAME], KOD_EDRPOU, FULLNAME);

	select [Result!TResult!Object] = null, Loaded = (select count(*) from @Banks);
end
go
------------------------------------------------
create or alter procedure cat.[Bank.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Banks set Void = 1 where TenantId = @TenantId and Id = @Id;
end
go



/* BANK ACCOUNT*/
------------------------------------------------
create or alter procedure cat.[BankAccount.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @ba table(rowno int identity(1, 1), id bigint, comp bigint, bank bigint, 
		crc bigint, rowcnt int);

	declare @fr nvarchar(255);
	set @fr = N'%' + upper(@Fragment) + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	insert into @ba(id, comp, bank, crc, rowcnt)
	select b.Id, b.Company, b.Bank, b.Currency, 
		count(*) over ()
	from cat.CashAccounts b
	where TenantId = @TenantId and b.IsCashAccount = 0 and (@fr is null or 
		b.[Name] like @fr or b.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order
				when N'accountno' then b.[AccountNo]
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'accountno' then b.[AccountNo]
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then b.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then b.[Id]
			end
		end desc,
		b.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [BankAccounts!TBankAccount!Array] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo, 
		[Company!TCompany!RefId] = ba.Company,
		[Currency!TCurrency!RefId] = ba.Currency,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.CashAccounts ba on t.id  = ba.Id and ba.TenantId = @TenantId
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

	select [!$System!] = null, [!BankAccounts!Offset] = @Offset, [!BankAccounts!PageSize] = @PageSize, 
		[!BankAccounts!SortOrder] = @Order, [!BankAccounts!SortDir] = @Dir,
		[!BankAccounts.Fragment!Filter] = @Fragment;
end
go
------------------------------------------------
create or alter procedure cat.[BankAccount.Simple.Index]
@TenantId int = 1,
@UserId bigint,
@Company bigint = null,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [BankAccounts!TBankAccount!Array] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo
	from cat.CashAccounts ba
	where ba.TenantId = @TenantId and (@Company is null or Company = @Company) and ba.IsCashAccount = 0;

	select [Company!TCompany!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Companies where TenantId = @TenantId and Id=@Company;
end
go
------------------------------------------------
create or alter procedure cat.[BankAccount.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [BankAccount!TBankAccount!Object] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo,
		[Company!TCompany!RefId] = ba.Company,
		[Currency!TCurrency!RefId] = ba.Currency,
		[Bank!TBank!RefId] = ba.Bank
	from cat.CashAccounts ba
	where TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join cat.CashAccounts ba on c.TenantId = ba.TenantId and ba.Company = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, c.Short
	from cat.Currencies c inner join cat.CashAccounts ba on c.TenantId = ba.TenantId and ba.Currency = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	-- TODO: // BASE Currency!
	select [Params!TParam!Object] = null, [Currency.Id!TCurrency!Id] = c.Id, [Currency.Short!TCurrency!] = c.Short
	from cat.Currencies c where TenantId = @TenantId and c.Id = 980;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;
end
go
---------------------------------------------
drop procedure if exists cat.[BankAccount.Metadata];
drop procedure if exists cat.[BankAccount.Update];
drop type if exists cat.[BankAccount.TableType];
go
------------------------------------------------
create type cat.[BankAccount.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	AccountNo nvarchar(255),
	Company bigint,
	[Memo] nvarchar(255),
	Currency bigint,
	Bank bigint
)
go
---------------------------------------------
create or alter procedure cat.[BankAccount.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @BankAccount cat.[BankAccount.TableType];
	select [BankAccount!BankAccount!Metadata] = null, * from @BankAccount;
end
go
---------------------------------------------
create or alter procedure cat.[BankAccount.Update]
@TenantId int = 1,
@UserId bigint,
@BankAccount cat.[BankAccount.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.CashAccounts as t
	using @BankAccount as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Company = s.Company,
		t.AccountNo = s.AccountNo,
		t.Currency = s.Currency,
		t.Bank = s.Bank
	when not matched by target then insert
		(TenantId, IsCashAccount, Company, [Name], AccountNo, Currency, Bank, Memo) values
		(@TenantId, 0, s.Company, s.[Name], s.AccountNo, s.Currency, s.Bank, s.Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[BankAccount.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[BankAccount.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.CashAccounts set Void = 1 where TenantId = @TenantId and Id = @Id and IsCashAccount = 0;
end
go

/* Cash ACCOUNT*/
------------------------------------------------
create or alter procedure cat.[CashAccount.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @ba table(rowno int identity(1, 1), id bigint, comp bigint, 
		crc bigint, rowcnt int);

	declare @fr nvarchar(255);
	set @fr = N'%' + upper(@Fragment) + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	insert into @ba(id, comp, crc, rowcnt)
	select c.Id, c.Company, c.Currency, 
		count(*) over ()
	from cat.CashAccounts c
	where TenantId = @TenantId and (@fr is null or 
		c.[Name] like @fr or c.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then c.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then c.[Id]
			end
		end desc,
		c.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo,
		[Company!TCompany!RefId] = ca.Company,
		[Currency!TCurrency!RefId] = ca.Currency,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.CashAccounts ca on t.id  = ca.Id and ca.TenantId = @TenantId and ca.IsCashAccount = 1
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

	select [!$System!] = null, [!CashAccounts!Offset] = @Offset, [!CashAccounts!PageSize] = @PageSize, 
		[!CashAccounts!SortOrder] = @Order, [!CashAccounts!SortDir] = @Dir,
		[!CashAccounts.Fragment!Filter] = @Fragment;
end
go
------------------------------------------------
create or alter procedure cat.[CashAccount.Simple.Index]
@TenantId int = 1,
@UserId bigint,
@Company bigint = null,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo
	from cat.CashAccounts ca
	where ca.TenantId = @TenantId and ca.Company = @Company and ca.IsCashAccount = 1;

	select [Company!TCompany!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Companies where TenantId = @TenantId and Id=@Company;
end
go
------------------------------------------------
create or alter procedure cat.[CashAccount.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CashAccount!TCashAccount!Object] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo,
		[Company!TCompany!RefId] = ca.Company,
		[Currency!TCurrency!RefId] = ca.Currency
	from cat.CashAccounts ca
	where TenantId = @TenantId and ca.Id = @Id and ca.IsCashAccount = 1;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join cat.CashAccounts ca on c.TenantId = ca.TenantId and ca.Company = c.Id
	where c.TenantId = @TenantId and ca.Id = @Id;

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, c.Short
	from cat.Currencies c inner join cat.CashAccounts ca on c.TenantId = ca.TenantId and ca.Currency = c.Id
	where c.TenantId = @TenantId and ca.Id = @Id;

	-- TODO: // BASE Currency!
	select [Params!TParam!Object] = null, [Currency.Id!TCurrency!Id] = c.Id, [Currency.Short!TCurrency!] = c.Short
	from cat.Currencies c where TenantId = @TenantId and c.Id = 980;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;
end
go
---------------------------------------------
drop procedure if exists cat.[CashAccount.Metadata];
drop procedure if exists cat.[CashAccount.Update];
drop type if exists cat.[CashAccount.TableType];
go
------------------------------------------------
create type cat.[CashAccount.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	Company bigint,
	[Memo] nvarchar(255),
	Currency bigint
)
go
---------------------------------------------
create or alter procedure cat.[CashAccount.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Cash cat.[CashAccount.TableType];
	select [CashAccount!CashAccount!Metadata] = null, * from @Cash;
end
go
---------------------------------------------
create or alter procedure cat.[CashAccount.Update]
@TenantId int = 1,
@UserId bigint,
@CashAccount cat.[CashAccount.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.CashAccounts as t
	using @CashAccount as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Company = s.Company,
		t.Currency = s.Currency
	when not matched by target then insert
		(TenantId, IsCashAccount, Company, [Name], Currency, Memo) values
		(@TenantId, 1, s.Company, s.[Name], s.Currency, s.Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[CashAccount.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[CashAccount.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.CashAccounts set Void = 1 where TenantId = @TenantId and Id = @Id and IsCashAccount = 1;
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
@UserId bigint,
@Id bigint = null
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

/* CURRENCY */
------------------------------------------------
create or alter procedure cat.[Currency.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = -1,
@Order nvarchar(32) = N'number3',
@Dir nvarchar(5) = N'asc',
@Id bigint = null,
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + upper(@Fragment) + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	select [Currencies!TCurrency!Array] = null,
		[Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo, 
		c.Alpha3, c.Number3, c.Denom, c.[Symbol]
	from cat.Currencies c
	where TenantId = @TenantId
		and (@fr is null or c.Alpha3 like @fr or c.Number3 like @fr 
		or c.[Name] like @fr or c.Memo like @fr)
	order by
		case when @Dir = N'asc' then
			case @Order
				when N'alpha3' then c.[Alpha3]
				when N'number3' then c.[Number3]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'alpha3' then c.[Alpha3]
				when N'number3' then c.[Number3]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc;

	select [!$System!] = null, [!Currencies!Offset] = @Offset, [!Currencies!PageSize] = @PageSize, 
		[!Currencies!SortOrder] = @Order, [!Currencies!SortDir] = @Dir,
		[!Currencies.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Currency.Catalog.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = -1,
@Order nvarchar(32) = N'number3',
@Dir nvarchar(5) = N'asc',
@Id bigint = null,
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	-- TenantId = 0 => From Catalog
	exec cat.[Currency.Index] @TenantId = 0, @UserId = @UserId, @Offset = @Offset,
		@PageSize = @PageSize, @Order=@Order, @Dir = @Dir, @Id = @Id, @Fragment = @Fragment;
end
go
------------------------------------------------
create or alter procedure cat.[Currency.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Currency!TCurrency!Object] = null,
		[Id!!Id] = c.Id, [NewId] = c.Id, [Name!!Name] = c.[Name], c.Memo, c.Alpha3, c.Number3, c.Denom, c.Symbol
	from cat.Currencies c
	where c.TenantId = @TenantId and c.Id = @Id;
end
go
---------------------------------------------
drop procedure if exists cat.[Currency.Metadata];
drop procedure if exists cat.[Currency.Update];
drop type if exists cat.[Currency.TableType];
go
---------------------------------------------
create type cat.[Currency.TableType] as table
(
	Id bigint,
	[NewId] bigint,
	[Alpha3] nchar(3),
	[Number3] nchar(3),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Denom int,
	[Symbol] nvarchar(3)
)
go
---------------------------------------------
create or alter procedure cat.[Currency.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Currency cat.[Currency.TableType];
	select [Currency!Currency!Metadata] = null, * from @Currency;
end
go
---------------------------------------------
create or alter procedure cat.[Currency.Update]
@TenantId int = 1,
@UserId bigint,
@Currency cat.[Currency.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Currencies as t
	using @Currency as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[Alpha3] = s.[Alpha3],
		t.[Number3] = s.Number3,
		t.[Symbol] = s.[Symbol],
		t.[Denom] = s.[Denom]
	when not matched by target then insert
		(TenantId, Id, [Name], Memo, Alpha3, Number3, [Symbol], [Denom]) values
		(@TenantId, s.[NewId], s.[Name], s.Memo, s.Alpha3, s.Number3, s.[Symbol], s.Denom)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Currency.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Currency.CheckDuplicate]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Number3 nvarchar(3)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @valid bit = 1;

	if exists(select 1 from cat.Currencies where TenantId = @TenantId and Number3 = @Number3 and Id <> @Id)
		set @valid = 0;

	select [Result!TResult!Object] = null, [Value] = @valid;
end
go
---------------------------------------------
create or alter procedure cat.[Currency.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Currencies set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go
---------------------------------------------
create or alter procedure cat.[Currency.AddFromCatalog]
@TenantId int = 1,
@UserId bigint,
@Ids nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	merge cat.Currencies as t
	using (
		select cs.Id, cs.Alpha3, cs.Number3, cs.[Symbol], cs.Denom, cs.[Name] from cat.Currencies cs 
			inner join string_split(@Ids, N',') t on cs.TenantId = 0 and cs.Id = t.[value]) as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set 
		Alpha3 = s.Alpha3,
		Number3 = s.Number3,
		[Symbol] = s.[Symbol],
		Denom = s.Denom,
		[Name] = s.[Name],
		Void = 0
	when not matched by target then insert
		(TenantId, Id, Alpha3, Number3, [Symbol], Denom, [Name]) values
		(@TenantId, s.Id, s.Alpha3, s.Number3, s.[Symbol], s.Denom, s.[Name]);
end
go

/* PRICELIST */
------------------------------------------------
create or alter procedure cat.[PriceList.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PriceLists!TPriceList!Array] = null;
end
go

/* Accounting plan */

------------------------------------------------
create or alter procedure acc.[Account.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with T(Id, Parent, [Level])
	as (
		select a.Id, Parent, 0 from
			acc.Accounts a where TenantId=@TenantId and a.Parent is null and a.[Plan] is null and Void=0
		union all 
		select a.Id, a.Parent, T.[Level] + 1 
		from acc.Accounts a
			inner join T on T.Id = a.Parent and a.TenantId = @TenantId and a.Void = 0
		where a.TenantId = @TenantId
	)
	select [Accounts!TAccount!Tree] = null, [Id!!Id] = T.Id, a.Code, a.[Name], a.[Plan], a.IsFolder,
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
@UserId bigint,
@Id bigint = null,
@Parent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Account!TAccount!Object] = null, [Id!!Id] = Id, Code, [Name], [Memo], [Plan], 
		ParentAccount = Parent, IsFolder, IsItem, IsWarehouse, IsAgent, IsBankAccount, IsCash, IsContract
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
	[ParentAccount] bigint,
	IsFolder bit,
	IsItem bit,
	IsWarehouse bit,
	IsAgent bit,
	IsBankAccount bit,
	IsCash bit,
	IsContract bit
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
		t.[Memo] = s.Memo,
		t.IsFolder = 1
	when not matched by target then insert
		(TenantId, Code, [Name], [Memo], IsFolder) values
		(@TenantId, s.Code, s.[Name], s.Memo, 1)
	output inserted.Id into @rtable(id);
	select @id = id from @rtable;
	exec acc.[Account.Plan.Load] @TenantId = @TenantId,
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
		t.[Memo] = s.Memo,
		t.IsFolder = s.IsFolder,
		t.IsItem = s.IsItem,
		t.IsAgent = s.IsAgent,
		t.IsWarehouse = s.IsWarehouse,
		t.IsBankAccount = s.IsBankAccount,
		t.IsCash = s.IsCash,
		t.IsContract = s.IsContract
	when not matched by target then insert
		(TenantId, [Plan], Parent, Code, [Name], [Memo], IsFolder, IsItem, IsAgent, IsWarehouse, 
			IsBankAccount, IsCash, IsContract) values
		(@TenantId, @plan, s.ParentAccount, s.Code, s.[Name], s.Memo, s.IsFolder, s.IsItem, s.IsAgent, s.IsWarehouse,
			s.IsBankAccount, s.IsCash, s.IsContract)
	output inserted.Id into @rtable(id);
	select @id = id from @rtable;
	exec acc.[Account.Load] @TenantId = @TenantId,
		@UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure acc.[Account.Plan.Browse.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	select [Accounts!TAccount!Array] = null, [Id!!Id] = Id, Code, [Name!!Name] = a.[Name]
	from acc.Accounts a
	where a.TenantId = @TenantId and Void = 0 and [Plan] is null and Parent is null and Void = 0
	order by a.Id;
end
go
------------------------------------------------
create or alter procedure acc.[Account.Browse.Index]
@TenantId int = 1,
@UserId bigint,
@Plan bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	with T(Id, Parent, Anchor, [Level])
	as (
		select a.Id, cast(null as bigint), Parent, 0 from
			acc.Accounts a where TenantId=@TenantId and a.Parent = @Plan and a.[Plan] = @Plan and Void=0
		union all 
		select a.Id, a.Parent, a.Parent, T.[Level] + 1 
		from acc.Accounts a
			inner join T on T.Id = a.Parent and a.TenantId = @TenantId
		where a.TenantId = @TenantId and a.[Plan] = [Plan] and a.Void = 0
	)
	select [Accounts!TAccount!Tree] = null, [Id!!Id] = T.Id, a.Code, a.[Name], a.[Plan],
		[Items!TAccount!Items] = null, [!TAccount.Items!ParentId] = T.Parent,
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash
	from T inner join acc.Accounts a on a.Id = T.Id and a.TenantId = @TenantId
	order by T.[Level], a.Code;
end
go
------------------------------------------------
create or alter procedure acc.[Account.BrowseAll.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	with T(Id, Parent, Anchor, [Level])
	as (
		select a.Id, cast(null as bigint), Parent, 0 from
			acc.Accounts a where TenantId=@TenantId and a.Parent is null and a.[Plan] is null and a.Void = 0
		union all 
		select a.Id, a.Parent, a.Parent, T.[Level] + 1 
		from acc.Accounts a
			inner join T on T.Id = a.Parent and a.TenantId = @TenantId
		where a.TenantId = @TenantId and a.[Plan] = [Plan] and a.Void = 0
	)
	select [Accounts!TAccount!Tree] = null, [Id!!Id] = T.Id, a.Code, a.[Name], a.[Plan], a.IsFolder,
		[Items!TAccount!Items] = null, [!TAccount.Items!ParentId] = T.Parent,
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash
	from T inner join acc.Accounts a on a.Id = T.Id and a.TenantId = @TenantId
	order by T.[Level], a.Code;
end
go
------------------------------------------------
create or alter procedure acc.[Account.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	update acc.Accounts set Void = 1 where TenantId = @TenantId and Id = @Id;
end
go


/* Operation */
-------------------------------------------------
create or alter procedure doc.[Operation.Plain.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[Journals!TOpJournal!Array] = null
	from doc.Operations where TenantId = @TenantId;
end
go
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
	throw 60000, @Id, 0;
	select [Children!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo
	from doc.Operations o;
	--where TenantId = @TenantId; -- and Menu = @Id
	--order by Id;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;


	select [Operation!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form!TForm!RefId] = o.Form,
		[JournalStore!TOpJournalStore!Array] = null,
		[Trans!TOpTrans!Array] = null
	from doc.Operations o
	where o.TenantId = @TenantId and o.Id=@Id;

	select [!TOpJournalStore!Array] = null, [Id!!Id] = Id, RowKind, IsIn, IsOut, 
		IsStorno = case when ojs.Factor = -1 then 1 else 0 end,
		[!TOperation.JournalStore!ParentId] = ojs.Operation
	from doc.OpJournalStore ojs 
	where ojs.TenantId = @TenantId and ojs.Operation = @Id;

	select [!TOpTrans!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		[Plan!TAccount!RefId] = [Plan], [Dt!TAccount!RefId] = Dt, [Ct!TAccount!RefId] = Ct, 
		DtAccMode, DtSum, DtRow, CtAccMode, CtSum, CtRow,
		[!TOperation.Trans!ParentId] = ot.Operation
	from doc.OpTrans ot 
	where ot.TenantId = @TenantId and ot.Operation = @Id
	order by ot.RowKind

	select [!TAccount!Map] = null, [Id!!Id] = a.Id, a.Code, [Name!!Name] = a.[Name],
		a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash
	from doc.OpTrans ot 
		left join acc.Accounts a on ot.TenantId = a.TenantId and a.Id in (ot.[Plan], ot.Dt, ot.Ct)
	where ot.TenantId = @TenantId and ot.Operation = @Id
	group by a.Id, a.Code, a.[Name], a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash;

	select [Forms!TForm!Array] = null, [Id!!Id] = df.Id, [Name!!Name] = df.[Name], 
		[RowKinds!TRowKind!Array] = null
	from doc.Forms df
	where df.TenantId = @TenantId
	order by df.[Order], df.Id;

	select [Menu!TMenu!Array] = null, [Id!!Id] = fm.Id, [Name], fm.[Category], 
		Checked = case when ml.Menu is not null then 1 else 0 end
	from doc.FormsMenu fm
		left join ui.OpMenuLinks ml on fm.TenantId = ml.TenantId and ml.Operation = @Id and fm.Id = ml.Menu
	where fm.TenantId = @TenantId
	order by fm.[Order];

	select [!TRowKind!Array] = null, [Id!!Id] = rk.Id, [Name!!Name] = rk.[Name], [!TForm.RowKinds!ParentId] = rk.Form
	from doc.FormRowKinds rk where rk.TenantId = @TenantId
	order by rk.[Order];
end
go
-------------------------------------------------
drop procedure if exists doc.[Operation.Metadata];
drop procedure if exists doc.[Operation.Update];
drop type if exists doc.[Operation.TableType];
drop type if exists doc.[OpJournalStore.TableType];
drop type if exists doc.[OpTrans.TableType];
drop type if exists doc.[OpMenu.TableType]
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
create type doc.[OpMenu.TableType]
as table(
	Id nvarchar(32),
	Checked bit
)
go
-------------------------------------------------
create type doc.[OpJournalStore.TableType]
as table(
	Id bigint,
	RowKind nvarchar(8),
	IsIn bit,
	IsOut bit,
	IsStorno bit
)
go
-------------------------------------------------
create type doc.[OpTrans.TableType]
as table(
	Id bigint,
	RowNo int,
	RowKind nvarchar(8),
	[Plan] bigint,
	[Dt] bigint,
	[Ct] bigint,
	DtAccMode nchar(1),
	DtRow nchar(1),
	DtSum nchar(1),
	CtAccMode nchar(1),
	CtRow nchar(1),
	CtSum nchar(1)
)
go
------------------------------------------------
create or alter procedure doc.[Operation.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Operation doc.[Operation.TableType];
	declare @JournalStore doc.[OpJournalStore.TableType];
	declare @OpTrans doc.[OpTrans.TableType];
	declare @OpMenu doc.[OpMenu.TableType];
	select [Operation!Operation!Metadata] = null, * from @Operation;
	select [JournalStore!Operation.JournalStore!Metadata] = null, * from @JournalStore;
	select [Trans!Operation.Trans!Metadata] = null, * from @OpTrans;
	select [Menu!Menu!Metadata] = null, * from @OpMenu;
end
go
------------------------------------------------
create or alter procedure doc.[Operation.Update]
@TenantId bigint = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Operation doc.[Operation.TableType] readonly,
@JournalStore doc.[OpJournalStore.TableType] readonly,
@Trans doc.[OpTrans.TableType] readonly,
@Menu doc.[OpMenu.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
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
		(TenantId, [Name], Form, Memo) values
		(@TenantId, s.[Name], s.Form, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @Id = id from @rtable;

	merge doc.OpJournalStore as t
	using @JournalStore as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowKind = isnull(s.RowKind, N''),
		t.IsIn = s.IsIn,
		t.IsOut = s.IsOut,
		t.Factor = case when s.IsStorno = 1 then -1 else 1 end
	when not matched by target then insert
		(TenantId, Operation, RowKind, IsIn, IsOut, Factor) values
		(@TenantId, @Id, isnull(RowKind, N''), s.IsIn, s.IsOut, case when s.IsStorno = 1 then -1 else 1 end)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	merge doc.OpTrans as t
	using @Trans as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowNo = s.RowNo,
		t.RowKind = isnull(s.RowKind, N''),
		t.[Plan] = s.[Plan],
		t.[Dt] = s.[Dt],
		t.[Ct] = s.[Ct],
		t.DtAccMode = s.DtAccMode,
		t.CtAccMode = s.CtAccMode,
		t.DtRow = s.DtRow,
		t.CtRow = s.CtRow,
		t.DtSum = s.DtSum,
		t.CtSum = s.CtSum
	when not matched by target then insert
		(TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct, DtAccMode, CtAccMode, DtRow, CtRow, 
			DtSum, CtSum) values
		(@TenantId, @Id, RowNo, isnull(RowKind, N''), s.[Plan], s.Dt, s.Ct, s.DtAccMode, s.CtAccMode, s.DtRow, s.CtRow, 
			s.DtSum, s.CtSum)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	with OM as (select Id from @Menu where Checked = 1)
	merge ui.OpMenuLinks as t
	using OM as s
	on t.TenantId = @TenantId and t.Operation = @Id and t.Menu = s.Id
	when not matched by target then insert
		(TenantId, Operation, Menu) values
		(@TenantId, @Id, s.Id)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

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
@Operation bigint = -1,
@Agent bigint = null,
@Warehouse bigint = null,
@Company bigint = null,
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date;
	set @end = dateadd(day, 1, @To);

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @docs table(rowno int identity(1, 1), id bigint, op bigint, agent bigint, 
		comp bigint, whfrom bigint, whto bigint, rowcnt int);

	insert into @docs(id, op, agent, comp, whfrom, whto, rowcnt)
	select d.Id, d.Operation, d.Agent, d.Company, d.WhFrom, d.WhTo,
		count(*) over()
	from doc.Documents d
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and d.Operation = ml.Operation
	where d.TenantId = @TenantId and ml.Menu = @Menu
		and (d.[Date] >= @From and d.[Date] < @end)
		and (@Operation = -1 or d.Operation = @Operation)
		and (@Agent is null or d.Agent = @Agent)
		and (@Company is null or d.Company = @Company)
		and (@Warehouse is null or d.WhFrom = @Warehouse or d.WhTo = @Warehouse)
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

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.Done,
		[Operation!TOperation!RefId] = d.Operation, 
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[WhFrom!TWarehouse!RefId] = d.WhFrom, [WhTo!TWarehouse!RefId] = d.WhTo,
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

	with W as (select wh = whfrom from @docs union all select wh = whto from @docs),
	T as (select wh from W group by wh)
	select [!TWarehouse!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Warehouses a 
		inner join T t on a.TenantId = @TenantId and a.Id = wh;

	with T as (select comp from @docs group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	-- menu
	select [Menu!TMenu!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], FormId = f.Id, FormName = f.[Name]
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by f.[Order] desc;

	-- filters
	select [Operations!TOperation!Array] = null, [Id!!Id] = -1, [Name!!Name] = N'@[Filter.AllOperations]', null, [!Order] = -1
	union all
	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form], [!Order] = o.Id
	from doc.Operations o
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by [!Order];

	select [!$System!] = null, [!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To,
		[!Documents.Operation!Filter] = @Operation, 
		[!Documents.Agent.Id!Filter] = @Agent, [!Documents.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent),
		[!Documents.Company.Id!Filter] = @Company, [!Documents.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!Documents.Warehouse.Id!Filter] = @Warehouse, [!Documents.Warehouse.Name!Filter] = cat.fn_GetWarehouseName(@TenantId, @Warehouse)
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Operation bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docform nvarchar(16);
	declare @done bit;
	if @Operation is null
		select @Operation = d.Operation from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id;

	select @docform = o.Form from doc.Operations o where o.TenantId = @TenantId and o.Id = @Operation;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum], d.Done,
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, [WhFrom!TWarehouse!RefId] = d.WhFrom,
		[WhTo!TWarehouse!RefId] = d.WhTo,
		[Rows!TRow!Array] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	declare @rows table(id bigint, item bigint, unit bigint);
	insert into @rows (id, item, unit)
	select Id, Item, Unit from doc.DocDetails dd
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

	select [!TWarehouse!Map] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name]
	from cat.Warehouses w inner join doc.Documents d on d.TenantId = w.TenantId and w.Id in (d.WhFrom, d.WhTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by w.Id, w.[Name];

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join doc.Documents d on d.TenantId = c.TenantId and d.Company = c.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	with T as (select item from @rows group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], Article,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit!] = u.Short
	from cat.Items i inner join T on i.Id = T.item and i.TenantId = @TenantId
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	where i.TenantId = @TenantId;

	with T as (select unit from @rows group by unit)
	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.Short
	from cat.Units u inner join T on u.Id = T.unit and u.TenantId = @TenantId
	where u.TenantId = @TenantId;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form]
	from doc.Operations o where TenantId = @TenantId and Form=@docform
	order by Id;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [Params!TParam!Object] = null, [Operation] = @Operation;

	select [!$System!] = null, [!!ReadOnly] = d.Done
	from doc.Documents d where TenantId = @TenantId and Id = @Id;
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
	WhFrom bigint,
	WhTo bigint,
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
	Unit bigint,
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
		t.WhFrom = s.WhFrom,
		t.WhTo = s.WhTo,
		t.Memo = s.Memo
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, WhFrom, WhTo, Memo, UserCreated) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, WhFrom, WhTo, s.Memo, @UserId)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	with DD as (select * from doc.DocDetails where TenantId = @TenantId and Document = @id)
	merge DD as t
	using @Rows as s on t.Id = s.Id
	when matched then update set
		t.RowNo = s.RowNo,
		t.Item = s.Item,
		t.Unit = s.Unit,
		t.Qty = s.Qty,
		t.Price = s.Price,
		t.[Sum] = s.[Sum]
	when not matched by target then insert
		(TenantId, Document, RowNo, Item, Unit, Qty, Price, [Sum]) values
		(@TenantId, @id, s.RowNo, s.Item, s.Unit, s.Qty, s.Price, s.[Sum])
	when not matched by source and t.TenantId = @TenantId and t.Document = @id then delete;

	exec doc.[Document.Stock.Load] @TenantId = @TenantId, 
	@UserId = @UserId, @Id = @id;
end
go

/* Document.Pay */
------------------------------------------------
create or alter procedure doc.[Document.Pay.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(255),
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Operation bigint = -1,
@Agent bigint = null,
@CashAccount bigint = null,
@Company bigint = null,
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date;
	set @end = dateadd(day, 1, @To);

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @docs table(rowno int identity(1, 1), id bigint, op bigint, agent bigint, 
		comp bigint, bafrom bigint, bato bigint, cafrom bigint, cato bigint, rowcnt int);

	insert into @docs(id, op, agent, comp, cafrom, cato, rowcnt)
	select d.Id, d.Operation, d.Agent, d.Company, d.CashAccFrom, d.CashAccTo,
		count(*) over()
	from doc.Documents d
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and d.Operation = ml.Operation
	where d.TenantId = @TenantId and ml.Menu = @Menu
		and (d.[Date] >= @From and d.[Date] < @end)
		and (@Operation = -1 or d.Operation = @Operation)
		and (@Agent is null or d.Agent = @Agent)
		and (@Company is null or d.Company = @Company)
		and (@CashAccount is null or d.CashAccFrom = @CashAccount or d.CashAccTo = @CashAccount)
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

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.Done,
		[Operation!TOperation!RefId] = d.Operation, 
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[CashAccFrom!TCashAccount!RefId] = d.CashAccFrom, [CashAccTo!TCashAccount!RefId] = d.CashAccTo,
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

	with C as (select ca = cafrom from @docs union all select cato from @docs),
	T as (select ca from C group by ca)
	select [!TCashAccount!Map] = null, [Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.[AccountNo]
	from cat.CashAccounts ca 
		inner join T t on ca.TenantId = @TenantId and ca.Id = ca;

	with T as (select comp from @docs group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	-- menu
	select [Menu!TMenu!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], FormId = f.Id, FormName = f.[Name]
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by f.[Order] desc;

	-- filters
	select [Operations!TOperation!Array] = null, [Id!!Id] = -1, [Name!!Name] = N'@[Filter.AllOperations]', null, [!Order] = -1
	union all
	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form], [!Order] = o.Id
	from doc.Operations o
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by [!Order];

	select [!$System!] = null, [!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To,
		[!Documents.Operation!Filter] = @Operation, 
		[!Documents.Agent.Id!Filter] = @Agent, [!Documents.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent),
		[!Documents.Company.Id!Filter] = @Company, [!Documents.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!Documents.CashAccount.Id!Filter] = @CashAccount, [!Documents.CashAccount.Name!Filter] = cat.fn_GetCashAccountName(@TenantId, @CashAccount);
end
go
------------------------------------------------
create or alter procedure doc.[Document.Pay.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Operation bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docform nvarchar(16);
	declare @done bit;

	if @Operation is null
		select @Operation = d.Operation from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id;

	select @docform = o.Form from doc.Operations o where o.TenantId = @TenantId and o.Id = @Operation;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum], d.Done,
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, 
		[CashAccFrom!TCashAccount!RefId] = d.CashAccFrom, [CashAccTo!TCashAccount!RefId] = d.CashAccTo,
		[Rows!TRow!Array] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form
	from doc.Operations o 
		left join doc.Documents d on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Documents d on d.TenantId = a.TenantId and d.Agent = a.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [!TCashAccount!Map] = null, [Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.AccountNo
	from cat.CashAccounts ca inner join doc.Documents d on d.TenantId = ca.TenantId and ca.Id in (d.CashAccFrom, d.CashAccTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by ca.Id, ca.[Name], ca.AccountNo;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join doc.Documents d on d.TenantId = c.TenantId and d.Company = c.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form]
	from doc.Operations where TenantId = @TenantId and Form=@docform
	order by Id;

	select [Params!TParam!Object] = null, [Operation] = @Operation;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [!$System!] = null, [!!ReadOnly] = d.Done
	from doc.Documents d where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
drop procedure if exists doc.[Document.Pay.Metadata];
drop procedure if exists doc.[Document.Pay.Update];
drop type if exists cat.[Document.Pay.TableType];
go
------------------------------------------------
create type cat.[Document.Pay.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Sum] money,
	Operation bigint,
	Agent bigint,
	Company bigint,
	CashAccFrom bigint,
	CashAccTo bigint,
	Memo nvarchar(255)
)
go
------------------------------------------------
create or alter procedure doc.[Document.Pay.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Document cat.[Document.Pay.TableType];
	select [Document!Document!Metadata] = null, * from @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Pay.Update]
@TenantId int = 1,
@UserId bigint,
@Document cat.[Document.Pay.TableType] readonly
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
		t.CashAccFrom = s.CashAccFrom,
		t.CashAccTo = s.CashAccTo,
		t.Memo = s.Memo
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, 
			CashAccFrom, CashAccTo, Memo, UserCreated) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, 
			s.CashAccFrom, s.CashAccTo, s.Memo, @UserId)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	exec doc.[Document.Pay.Load] @TenantId = @TenantId, 
	@UserId = @UserId, @Id = @id;
end
go


/* Document Apply */
------------------------------------------------
create or alter procedure doc.[Document.Apply.Account]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	-- ensure empty journal
	delete from jrn.Journal where TenantId = @TenantId and Document = @Id;

	declare @tr table([date] datetime, detail bigint, trno int, rowno int, acc bigint, corracc bigint, [plan] bigint,
		dtct smallint, [sum] money, ssum money, qty float, item bigint, comp bigint, agent bigint, wh bigint, 
		ca bigint, _modesum nchar(1), _moderow nchar(1));

	declare @rowno int, @rowkind nvarchar(16), @plan bigint, @dt bigint, @ct bigint, @dtrow nchar(1), @ctrow nchar(1),
		@dtsum nchar(1), @ctsum nchar(1);

	-- todo: temportary source and accounts from other tables

	declare cur cursor local forward_only read_only fast_forward for
		select RowNo, RowKind, [Plan], [Dt], [Ct], 
			isnull(DtRow, N''), isnull(CtRow, N''), isnull(DtSum, N''), isnull(CtSum, N'')
		from doc.OpTrans where TenantId = @TenantId and Operation = @Operation;
	open cur;
	fetch next from cur into @rowno, @rowkind, @plan, @dt, @ct, @dtrow, @ctrow, @dtsum, @ctsum
	while @@fetch_status = 0
	begin
		-- debit
		if @dtrow = N'R'
			insert into @tr(_moderow, _modesum, [date], detail, trno, rowno, dtct, [plan], acc, corracc, item, qty, [sum], comp, agent, wh, ca)
				select @dtrow, @dtsum, d.[Date], dd.Id, @rowno, dd.RowNo, 1, @plan, @dt, @ct, dd.Item, dd.Qty, dd.[Sum], d.Company, d.Agent, d.WhTo,
					d.CashAccTo
				from doc.DocDetails dd inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
				where d.TenantId = @TenantId and d.Id = @Id and @rowkind = isnull(dd.Kind, N'');
		else if @dtrow = N''
			insert into @tr(_moderow, _modesum, [date], trno, dtct, [plan], acc, corracc, [sum], comp, agent, wh, ca)
				select @dtrow, @dtsum, d.[Date], @rowno, 1, @plan, @dt, @ct, d.[Sum], d.Company, d.Agent, d.WhTo,
					d.CashAccTo
				from doc.Documents d where TenantId = @TenantId and Id = @Id;
		-- credit
		if @ctrow = N'R'
			insert into @tr(_moderow, _modesum, [date], detail, trno, rowno, dtct, [plan], acc, corracc, item, qty, [sum], comp, agent, wh, ca)
				select @ctrow, @ctsum, d.[Date], dd.Id, @rowno, dd.RowNo, -1, @plan, @ct, @dt, dd.Item, dd.Qty, dd.[Sum], d.Company, d.Agent, d.WhFrom,
					d.CashAccFrom
				from doc.DocDetails dd inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
				where d.TenantId = @TenantId and d.Id = @Id and @rowkind = isnull(dd.Kind, N'');
		else if @ctrow = N''
			insert into @tr(_moderow, _modesum, [date], trno, dtct, [plan], acc, corracc, [sum], comp, agent, wh, ca)
				select @ctrow, @ctsum, d.[Date], @rowno, -1, @plan, @ct, @dt, d.[Sum], d.Company, d.Agent, d.WhFrom,
					d.CashAccFrom
				from doc.Documents d where TenantId = @TenantId and Id = @Id;
		fetch next from cur into @rowno, @rowkind, @plan, @dt, @ct, @dtrow, @ctrow, @dtsum, @ctsum
	end
	close cur;
	deallocate cur;

	if exists(select 1 from @tr where _modesum = N'S' and _moderow = 'R') 
	begin
		with W(item, ssum) as (
			select t.item, [sum] = sum(j.[Sum]) / sum(j.Qty)
			from jrn.Journal j 
			  inner join @tr t on j.Item = t.item and j.Account = t.acc and j.DtCt = 1 and j.[Date] <= t.[date]
			where j.TenantId = @TenantId and t._modesum = N'S' and _moderow = 'R'
			group by t.item
		)
		update @tr set [ssum] = W.ssum * t.qty
		from @tr t inner join W on t.item = W.item
		where t._modesum = N'S' and _moderow = 'R'
	end

	if exists(select 1 from @tr where _modesum = N'S' and _moderow = N'')
	begin
		-- total self cost for this transaction
		with W(trno, ssum) as (
			select trno, sum(ssum) from @tr t
			where t._modesum  = 'S' and _moderow = N'R'
			group by trno
		)
		update @tr set [ssum] = W.ssum 
		from @tr t inner join W on t.trno = W.trno
		where t._modesum = N'S' and t._moderow = N'';
	end

	insert into jrn.Journal(TenantId, Document, Detail, TrNo, RowNo, [Date],  Company, Warehouse, Agent, Item, 
		DtCt, [Plan], Account, CorrAccount, Qty, CashAccount, [Sum])
	select @TenantId, @Id, detail, trno, rowno, [date], comp, wh, agent, item,
		dtct, [plan], acc, corracc, qty, ca,
		case _modesum
			when N'S' then ssum
			when N'R' then [sum] - ssum
			else [sum]
		end
	from @tr;
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

	declare @journal table(
		Document bigint, Detail bigint, Company bigint, WhFrom bigint, WhTo bigint,
		Item bigint, Qty float, [Sum] money, Kind nchar(4)
	);
	insert into @journal(Document, Detail, Company, WhFrom, WhTo, Item, Qty, [Sum], Kind)
	select d.Id, dd.Id, d.Company, d.WhFrom, d.WhTo, dd.Item, dd.Qty, dd.[Sum], isnull(dd.Kind, N'')
	from doc.DocDetails dd 
		inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
	where d.TenantId = @TenantId and d.Id = @Id;

	-- out
	insert into jrn.StockJournal(TenantId, Dir, Warehouse, Document, Detail, Company, Item, Qty, [Sum])
	select @TenantId, -1, j.WhFrom, j.Document, j.Detail, j.Company, j.Item, j.Qty, 
		j.[Sum] * js.Factor
	from @journal j inner join doc.OpJournalStore js on js.Operation = @Operation and isnull(js.RowKind, N'') = j.Kind
	where js.TenantId = @TenantId and js.Operation = @Operation and js.IsOut = 1;

	-- in
	insert into jrn.StockJournal(TenantId, Dir, Warehouse, Document, Detail, Company, Item, Qty, [Sum])
	select @TenantId, 1, j.WhTo, j.Document, j.Detail, j.Company, j.Item, j.Qty, 
		j.[Sum] * js.Factor
	from @journal j inner join doc.OpJournalStore js on js.Operation = @Operation and isnull(js.RowKind, N'') = j.Kind
	where js.TenantId = @TenantId and js.Operation = @Operation and js.IsIn = 1;
end
go
------------------------------------------------
create or alter procedure doc.[Document.UnApply]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	begin tran
	delete from jrn.StockJournal where TenantId = @TenantId and Document = @Id;
	delete from jrn.Journal where TenantId = @TenantId and Document = @Id;
	update doc.Documents set Done = 0, DateApplied = null
		where TenantId = @TenantId and Id = @Id;
	commit tran
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply]
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
	
	declare @stock bit; -- stock journal
	declare @pay bit;   -- pay journal
	declare @acc bit;   -- acc journal

	/*
	if exists(select * from doc.OpJournalStore 
			where TenantId = @TenantId and Operation = @operation and (IsIn = 1 or IsOut = 1))
		set @stock = 1;
	*/
	if exists(select * from doc.OpTrans 
			where TenantId = @TenantId and Operation = @operation)
		set @acc = 1;

	begin tran
		/*
		if @stock = 1
			exec doc.[Document.Apply.Stock] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		*/
		if @acc = 1
			exec doc.[Document.Apply.Account] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		update doc.Documents set Done = 1, DateApplied = getdate() 
			where TenantId = @TenantId and Id = @Id;
	commit tran

end
go


/* Document.Dialogs */
------------------------------------------------
create or alter view doc.[view.Document.Transactions]
as
select [!TTransPart!Array] = null, [Id!!Id] = j.Id,
	[Account.Code!TAccount!] = a.Code, j.[Sum], j.Qty,
	[Item.Id!TItem!Id] = i.Id, [Item.Name!TItem] = i.[Name],
	[Warehouse.Id!TWarehouse!Id] = w.Id, [Warehouse.Name!TWarehouse] = w.[Name],
	[Agent.Id!TAgent!Id] = g.Id, [Agent.Name!TAgent] = g.[Name],
	[CashAcc.Id!TCashAcc!Id] = ca.Id, [CashAcc.Name!TCashAcc] = ca.[Name], 
		[CashAcc.No!TCashAcc!] = ca.AccountNo, [CashAcc.IsCash!TCashAcc!] = ca.IsCashAccount,
	[!TenantId] = j.TenantId, [!Document] = j.Document, [!DtCt] = j.DtCt, [!TrNo] = j.TrNo, [!RowNo] = j.RowNo
from jrn.Journal j 
	inner join acc.Accounts a on j.TenantId = a.TenantId and j.Account = a.Id
	left join cat.Items i on j.TenantId = i.TenantId and j.Item = i.Id and a.IsItem = 1
	left join cat.Warehouses w on j.TenantId = w.TenantId and j.Warehouse = w.Id and a.IsWarehouse = 1
	left join cat.Agents g on j.TenantId = g.TenantId and j.Agent = g.Id and a.IsAgent = 1
	left join cat.CashAccounts ca on j.TenantId = ca.TenantId and j.CashAccount = ca.Id 
		and (a.IsCash = 1 or a.IsBankAccount = 1)
go
------------------------------------------------
create or alter procedure doc.[Document.Transactions.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Transactions!TTrans!Array] = null,
		[Id!!Id] = TrNo, [Dt!TTransPart!Array] = null, [Ct!TTransPart!Array] = null
	from jrn.Journal j
	where j.TenantId = @TenantId and j.Document = @Id
	group by [TrNo]
	order by TrNo;

	-- dt
	select *, [!TTrans.Dt!ParentId] = [!TrNo]
	from doc.[view.Document.Transactions]
	where [!TenantId] = @TenantId and [!Document] = @Id and [!DtCt] = 1
	order by [!RowNo];

	-- ct
	select *, [!TTrans.Ct!ParentId] = [!TrNo]
	from doc.[view.Document.Transactions]
	where [!TenantId] = @TenantId and [!Document] = @Id and [!DtCt] = -1
	order by [!RowNo];
end
go

-- reports
-------------------------------------------------
create or alter procedure rep.[Report.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Reports!TReport!Array] = null, [Id!!Id] = r.Id, [Name!!Name] = [Name], Memo,
		Menu, [File!TRepFile!RefId] = [File], r.Account
	from rep.Reports r
	where TenantId = @TenantId and [Menu] = @Menu;

	select [!TRepFile!Map] = null, [Id!!Id] = rf.Id, [Url]
	from rep.RepFiles rf inner join rep.Reports r on r.TenantId = rf.TenantId and r.[File] = rf.[Id]
	where r.TenantId = @TenantId and r.Menu = @Menu;

	select [Params!TParam!Object] = null, Menu = @Menu;
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Menu nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = [Name], Memo,
		[Menu], [File!TRepFile!RefId] = [File], [Account!TAccount!RefId] = Account,
		[Type!TRepType!RefId] = [Type]
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = a.Id, [Code], [Name!!Name] = a.[Name],
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash
	from acc.Accounts a inner join rep.Reports r on a.TenantId = r.TenantId and a.Id = r.Account
	where r.TenantId = @TenantId and r.Id = @Id;

	select [RepTypes!TRepType!Array] = null, [Id!!Id] = rt.Id, [Name!!Name] = rt.[Name],
		UseAccount, [UsePlan], [Files!TRepFile!Array] = null
	from rep.RepTypes rt where TenantId = @TenantId order by rt.[Order];

	select [!TRepFile!Array] = null, [Id!!Id] = rf.Id, [Name!!Name] = rf.[Name],
		[!TRepType.Files!ParentId] = [Type], [Url]
	from rep.RepFiles rf where TenantId = @TenantId order by rf.[Order]

	select [Params!TParam!Object] = null, Menu = @Menu;
end
go
-------------------------------------------------
drop procedure if exists rep.[Report.Metadata];
drop procedure if exists rep.[Report.Update];
drop type if exists rep.[Report.TableType];
go
-------------------------------------------------
create type rep.[Report.TableType] as table (
	Id bigint,
	[Menu] nvarchar(32),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Type] nvarchar(16),
	[File] nvarchar(16),
	Account bigint
);
go
-------------------------------------------------
create or alter procedure rep.[Report.Metadata]
as
begin
	set nocount on;
	declare @Report rep.[Report.TableType];
	select [Report!Report!Metadata] = null, * from @Report;
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Update]
@TenantId int = 1,
@UserId bigint,
@Report rep.[Report.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge rep.Reports as t
	using @Report as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Type] = s.[Type],
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Account = s.Account,
		t.[File] = s.[File]
	when not matched by target then insert
		(TenantId, [Type], Menu, [Name], Memo, Account, [File]) values
		(@TenantId, s.[Type], s.Menu, [Name], Memo, Account, [File])
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec rep.[Report.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Menu nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	delete from rep.Reports where TenantId = @TenantId and Id = @Id;
end
go
-- reports stock
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Item.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null,
@Warehouse bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company), @Warehouse = isnull(@Warehouse, Warehouse)
	from usr.Defaults where TenantId = @TenantId and UserId = @UserId;

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	select Item,
		StartQty = sum(case when [Date] < @From then Qty * DtCt else 0 end),
		InQty = sum(case when [Date] >= @From and DtCt = 1 then Qty else 0 end),
		OutQty = sum(case when [Date] >= @From and DtCt = -1 then Qty else 0 end),
		StartSum = sum(case when [Date] < @From then [Sum] * DtCt else 0 end),
		InSum = sum(case when [Date] >= @From and DtCt = 1 then [Sum] else 0 end),
		OutSum = sum(case when [Date] >= @From and DtCt = -1 then [Sum] else 0 end),
		EndQty = cast(0 as float),
		EndSum  = cast(0 as money),
		ItemGroup = grouping(Item)
	into #tmp
	from jrn.Journal where TenantId = @TenantId and Account = @acc and Company = @Company
		and Warehouse = @Warehouse
		and [Date] < @end
	group by rollup(Item);

	update #tmp set EndQty = StartQty + InQty - OutQty, EndSum = StartSum + InSum - OutSum;

	-- turnover

	select [RepData!TRepData!Group] = null, 
		[Item!!GroupMarker] = ItemGroup,
		[Id!!Id] = t.Item,
		[Item!TItem!RefId] = t.Item,
		StartQty, StartSum, InQty, InSum, OutQty, OutSum, EndQty, EndSum,
		[Items!TRepData!Items] = null
	from #tmp t
	order by ItemGroup desc;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TItem!Map] = null, [Id!!Id] = Id, [Name!!Name] = i.[Name], i.Article
	from #tmp t inner join cat.Items i on i.TenantId = @TenantId and t.Item = i.Id


	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!RepData.Warehouse.Id!Filter] = @Warehouse, [!RepData.Warehouse.Name!Filter] = cat.fn_GetWarehouseName(@TenantId, @Warehouse)
end
go

-- reports stock
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Agent.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company)
	from usr.Defaults where TenantId = @TenantId and UserId = @UserId;

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	select Agent,
		StartSum = sum(case when [Date] < @From then [Sum] * DtCt else 0 end),
		InSum = sum(case when [Date] >= @From and DtCt = 1 then [Sum] else 0 end),
		OutSum = sum(case when [Date] >= @From and DtCt = -1 then [Sum] else 0 end),
		EndSum  = cast(0 as money),
		AgentGroup = grouping(Agent)
	into #tmp
	from jrn.Journal where TenantId = @TenantId and Account = @acc and Company = @Company
		and [Date] < @end
	group by rollup(Agent);

	update #tmp set EndSum = isnull(StartSum, 0) + isnull(InSum, 0) - isnull(OutSum, 0);

	-- turnover

	select [RepData!TRepData!Group] = null, 
		[Agent!!GroupMarker] = AgentGroup,
		[Id!!Id] = t.Agent,
		[Agent!TAgent!RefId] = t.Agent,
		StartSum, InSum, OutSum, EndSum,
		[Items!TRepData!Items] = null
	from #tmp t
	order by AgentGroup desc;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from #tmp t inner join cat.Agents a on a.TenantId = @TenantId and t.Agent = a.Id

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go

-- reports account
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Account.Agent.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company)
	from usr.Defaults where TenantId = @TenantId and UserId = @UserId;

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	
	select [Agent] = j.[Agent], Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when DtCt =  1 and j.[Date] < @From then [Sum] else 0 end,
		CtStart = case when DtCt = -1 and j.[Date] < @From then [Sum] else 0 end,
		DtSum = case when DtCt = 1 and j.[Date] >= @From then [Sum] else 0 end,
		CtSum = case when DtCt = -1 and j.[Date] >= @From then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
		and [Date] >= @From and [Date] < @end;

	with T as (
		select [Agent],
			DtStart = sum(DtStart), CtStart = sum(CtStart),
			DtSum = sum(DtSum), CtSum = sum(CtSum), 
			DtEnd = sum(DtStart) + sum(DtSum), 
			CtEnd = sum(CtStart) + sum(CtSum),
			GrpAgent = grouping([Agent])
		from #tmp 
		group by rollup([Agent])
	) select [RepData!TRepData!Group] = null, [Id!!Id] = Agent, [Agent!TAgent!RefId] = Agent,
		DtStart, CtStart,
		DtSum, CtSum,
		DtEnd, CtEnd,
		[Agent!!GroupMarker] = GrpAgent,
		[DtCross!TCross!CrossArray] = null,
		[CtCross!TCross!CrossArray] = null,
		[Items!TRepData!Items] = null
	from T
	order by GrpAgent desc;

	-- agents
	with TA as (select Agent from #tmp group by Agent) 
	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA t on a.TenantId = @TenantId and a.Id = t.Agent;

	-- dt cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[DtSum]), [!TRepData.DtCross!ParentId] = t.Agent
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = 1
	group by a.Code, t.Agent;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), [!TRepData.CtCross!ParentId] = t.Agent
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1
	group by a.Code, t.Agent;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
-------------------------------------------------
create or alter procedure [rep].[Report.Turnover.Account.Date.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company)
	from usr.Defaults where TenantId = @TenantId and UserId = @UserId;

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @start money;
	select @start = sum(j.[Sum] * j.DtCt)
	from jrn.Journal j where TenantId = @TenantId and Company = @Company and Account = @acc and [Date] < @From;
	set @start = isnull(@start, 0);
	
	select [Date] = j.[Date], Id=cast([Date] as int), Acc = j.Account, CorrAcc = j.CorrAccount,
		DtCt = j.DtCt,
		DtSum = case when DtCt = 1 then [Sum] else 0 end,
		CtSum = case when DtCt = -1 then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
		and [Date] >= @From and [Date] < @end;

	with T as (
		select [Date] = cast([Date] as date), Id=cast([Date] as int),
			DtSum = sum(DtSum), CtSum = sum(CtSum),
			GrpDate = grouping([Date])
		from #tmp 
		group by rollup([Date])
	) select [RepData!TRepData!Group] = null, [Id!!Id] = Id, [Date],
		StartSum = @start + coalesce(sum(DtSum - CtSum) over (
			partition by GrpDate order by [Date]
			rows between unbounded preceding and 1 preceding), 0
		),
		DtSum, CtSum,
		EndSum = @start + sum(DtSum - CtSum) over (
			partition by GrpDate order by [Date]
			rows between unbounded preceding and current row
		),
		[Date!!GroupMarker] = GrpDate,
		[DtCross!TCross!CrossArray] = null,
		[CtCross!TCross!CrossArray] = null,
		[Items!TRepData!Items] = null
	from T
	order by GrpDate desc;

	-- dt cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[DtSum]), [!TRepData.DtCross!ParentId] = t.Id
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = 1
	group by a.Code, t.Id;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), [!TRepData.CtCross!ParentId] = t.Id
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1
	group by a.Code, t.Id;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
--exec rep.[Report.Turnover.Account.Date.Load] 1, 99, 1027 --, N'20220301', N'20220331';
go




-- reports plan
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Plan.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company)
		from usr.Defaults where TenantId = @TenantId and UserId = @UserId;
	declare @comp bigint = nullif(@Company, -1);

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;


	declare @totbl table (account bigint, startsum money, dtsum money, ctsum money, endsum money, grp tinyint);

	insert into @totbl (account, startsum, dtsum, ctsum, endsum, grp)
	select
		j.Account,
		sum(case when j.[Date] < @From then j.[Sum] * j.DtCt else 0 end),
		sum(case when j.[Date] >= @From and j.DtCt = 1 then j.[Sum] else 0 end),
		sum(case when j.[Date] >= @From and j.DtCt = -1 then j.[Sum] else 0 end),
		sum(j.[Sum] * j.DtCt),
		grouping(j.Account)
	from
		jrn.Journal j
	where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and j.[Date] < @end and j.[Plan] = @acc
	group by rollup(j.Account) -- case A.UseAgent when 1 then J.Agent else null end;
	
	select [RepData!TRepData!Group] = null,
		AccCode = a.Code,
		AccName = a.[Name],
		AccId = a.Id,
		DtStart = case when t.startsum > 0 then t.startsum else 0 end,
		CtStart = -(case when t.startsum < 0 then t.startsum else 0 end),
		DtSum =  t.dtsum,
		CtSum = t.ctsum,
		DtEnd = case when t.endsum > 0 then t.endsum else 0 end,
		CtEnd = -case when t.endsum < 0 then t.endsum else 0 end,
		[Account!!GroupMarker] = t.grp,
		[Items!TRepData!Items] = null
	from @totbl t
		left join acc.Accounts a on a.TenantId = @TenantId and a.Id = t.account

	order by t.grp desc, a.Code;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Plan.Cashflow.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company)
	from usr.Defaults where TenantId = @TenantId and UserId = @UserId;

	declare @plan bigint;
	select @plan = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @accs table(id int);

	insert into @accs(id)
	select Id
	from acc.Accounts a where TenantId = @TenantId and [Plan] = @plan 
		and IsFolder = 0 and (IsCash = 1 or IsBankAccount = 1);
	
	with T as (
		select ca.IsCashAccount, 
			j.CashAccount,
			StartSum = sum(case when j.[Date] < @From then j.[Sum] * j.DtCt else 0 end),
			DtSum = sum(case when j.[Date] >= @From and j.DtCt = 1 then j.[Sum] else 0 end),
			CtSum = sum(case when j.[Date] >= @From and j.DtCt = -1 then j.[Sum] else 0 end),
			EndSum = sum(j.[Sum] * j.DtCt),
			GrpGroup = grouping(ca.IsCashAccount),
			GrpAccount = grouping(j.CashAccount)
		from jrn.Journal j
			inner join @accs a on  j.TenantId = @TenantId and j.Account = a.id
			left join cat.CashAccounts ca on ca.TenantId = j.TenantId and j.CashAccount = ca.Id
		where j.TenantId = @TenantId and j.[Date] < @end and j.Company = @Company
		group by rollup(ca.IsCashAccount, j.CashAccount)
	)
	select [RepData!TRepData!Group] = null,
		[GrpName] = 
		case T.IsCashAccount
			when 1 then N'Каса'
			when 0 then N'Рахунки в банках'
			else null
		end,
		[Name] = isnull(ca.[Name], ca.AccountNo),
		[Currency] = c.Short,
		StartSum, DtSum, CtSum, EndSum,
		[GrpName!!GroupMarker] = GrpGroup,
		[Name!!GroupMarker] = GrpAccount,
		[Items!TRepData!Items] = null
	from T
		left join cat.CashAccounts ca on ca.TenantId = @TenantId and ca.Id = T.CashAccount
		left join cat.Currencies c on ca.TenantId = c.TenantId and ca.Currency = c.Id
	order by GrpGroup desc, GrpAccount desc;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @plan;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go

--exec rep.[Report.Turnover.Plan.Load] 1, 99, 1045
--exec rep.[Report.Plan.Cashflow.Load] 1, 99, 1050;
go
-- DEBUG
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'debug')
	exec sp_executesql N'create schema debug';
go
------------------------------------------------
grant execute on schema::debug to public;
go
------------------------------------------------
create or alter procedure debug.[TestEnvironment.Create]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	begin tran;
	delete from rep.Reports where TenantId = @TenantId;
	delete from jrn.Journal where TenantId = @TenantId;
	delete from doc.DocDetails where TenantId = @TenantId;
	delete from doc.Documents where TenantId = @TenantId;
	delete from doc.OpTrans where TenantId = @TenantId;
	delete from ui.OpMenuLinks where TenantId = @TenantId;
	delete from doc.Operations where TenantId = @TenantId;
	delete from acc.Accounts where TenantId = @TenantId;
	commit tran;

	insert into acc.Accounts(TenantId, Id, [Plan], Parent, IsFolder, Code, [Name], IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, IsContract)
	values
		(@TenantId,  10, null, null, 1, N'УПР', N'Управлінський', null, null, null, null, null, null),
		(@TenantId, 281,   10,   10, 0, N'281', N'Товари',          1, 0, 1, 0, 0, 0),
		(@TenantId, 361,   10,   10, 0, N'361', N'Покупці',         0, 1, 0, 0, 0, 1),
		(@TenantId, 631,   10,   10, 0, N'631', N'Постачальники',   0, 1, 0, 0, 1, 1),
		(@TenantId, 301,   10,   10, 0, N'301', N'Каса',            0, 0, 0, 0, 1, 0),
		(@TenantId, 311,   10,   10, 0, N'311', N'Рахунки в банку', 0, 0, 0, 1, 0, 0),
		(@TenantId, 702,   10,   10, 0, N'702', N'Доходи',          0, 0, 0, 0, 0, 0),
		(@TenantId, 902,   10,   10, 0, N'902', N'Собівартість',    0, 0, 0, 0, 0, 0);

	insert into doc.Operations (TenantId, Id, [Name], [Form]) values
		(@TenantId, 100, N'Закупка товарів',				N'waybillin'),
		(@TenantId, 101, N'Оплата постачальнику (банк)',	N'payout'),
		(@TenantId, 102, N'Оплата постачальнику (готівка)',	N'cashout'),
		(@TenantId, 103, N'Відвантаження товарів',			N'waybillout'),
		(@TenantId, 104, N'Оплата від покупця (банк)',		N'payin'),
		(@TenantId, 105, N'Оплата від покупця (готівка)',	N'cashin');

	insert into doc.OpTrans(TenantId, Id, Operation, RowNo, RowKind, [Plan], Dt, Ct, [DtSum], DtRow, [CtSum], [CtRow])
	values
	(@TenantId, 106, 104, 1, N'', 10, 311, 361, null, null, null, null),
	(@TenantId, 107, 102, 1, N'', 10, 631, 301, null, null, null, null),
	(@TenantId, 108, 101, 1, N'', 10, 631, 311, null, null, null, null),
	(@TenantId, 109, 100, 1, N'', 10, 281, 631, null, N'R', null, null),
	(@TenantId, 110, 105, 1, N'', 10, 301, 361, null, null, null, null),
	(@TenantId, 111, 103, 1, N'', 10, 361, 702, null, null, null, null),
	(@TenantId, 112, 103, 2, N'', 10, 902, 281, N'S', null, N'S', N'R');

	insert into ui.OpMenuLinks(TenantId, Operation, Menu) values
	(@TenantId, 100, N'Purchase.Purchase'),
	(@TenantId, 101, N'Accounting.Bank'),
	(@TenantId, 101, N'Purchase.Payment'),
	(@TenantId, 102, N'Accounting.Cash'),
	(@TenantId, 102, N'Purchase.Payment'),
	(@TenantId, 103, N'Sales.Sales'),
	(@TenantId, 104, N'Accounting.Bank'),
	(@TenantId, 104, N'Sales.Payment'),
	(@TenantId, 105, N'Accounting.Cash'),
	(@TenantId, 105, N'Sales.Payment');

	/*
	select * from doc.Operations where TenantId = 1;
	select N'(@TenantId, ' + cast(Operation - 1000 + 100 as nvarchar) + ', N''' +  Menu + N'''),'
	from ui.OpMenuLinks where TenantId = 1;
	*/

	/*
	select ot.Id, Operation, RowNo, RowKind, ot.[Plan], Dt=da.Code, Ct=ca.Code, DtSum, DtRow, CtSum, CtRow
	from doc.OpTrans ot
	inner join acc.Accounts da on ot.Dt = da.Id
	inner join acc.Accounts ca on ot.Ct = ca.Id
	where ot. TenantId = 1
	order by ot.Id
	*/
end
go


/*
admin
*/
------------------------------------------------
if not exists(select * from appsec.Tenants where Id <> 0)
begin
	set nocount on;

	insert into appsec.Tenants(Id) values (1);
end
go
------------------------------------------------
if not exists(select * from appsec.Tenants where Id = 0)
begin
	set nocount on;

	insert into appsec.Tenants(Id) values (0);
end
go
------------------------------------------------
if not exists(select * from appsec.Users where Id <> 0)
begin
	set nocount on;
	set transaction isolation level read committed;

	insert into appsec.Users(Id, Tenant, UserName, SecurityStamp, PasswordHash, PersonName, EmailConfirmed)
	values (99, 1, N'admin@admin.com', N'c9bb451a-9d2b-4b26-9499-2d7d408ce54e', N'AJcfzvC7DCiRrfPmbVoigR7J8fHoK/xdtcWwahHDYJfKSKSWwX5pu9ChtxmE7Rs4Vg==',
		N'System administrator', 1);
end
go

/*
initial data
*/
------------------------------------------------
-- Default catalogs
create or alter procedure ini.[Cat.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;
	if not exists(select * from cat.Companies where TenantId = @TenantId)
		insert into cat.Companies (TenantId, [Name]) values (@TenantId, N'Моє підприємство');
	if not exists(select * from cat.Warehouses where TenantId = @TenantId)
		insert into cat.Warehouses(TenantId, [Name]) values (@TenantId, N'Основний склад');
	if not exists(select * from cat.Currencies where Id=980 and TenantId = @TenantId)
		insert into cat.Currencies(TenantId, Id, Short, Alpha3, Number3, [Symbol], Denom, [Name]) values
			(@TenantId, 980, N'грн', N'UAH', N'980', N'₴', 1, N'Українська гривня');
end
go
-------------------------------------------------
create or alter procedure ini.[Rep.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	declare @rt table(Id nvarchar(16), [Order] int, [Name] nvarchar(255), UseAccount bit, [UsePlan] bit);
	insert into @rt (Id, [Order], [Name], UseAccount, [UsePlan]) values
		(N'by.account', 10, N'@[By.Account]', 1, 0),
		(N'by.plan',    20, N'@[By.Plan]',    0, 1)
	merge rep.RepTypes as t
	using @rt as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.UseAccount = s.UseAccount,
		t.[UsePlan] = s.[UsePlan]
	when not matched by target then insert
		(TenantId, Id, [Name], [Order], UseAccount, [UsePlan]) values
		(@TenantId, s.Id, s.[Name], [Order], UseAccount, [UsePlan])
	when not matched by source and t.TenantId = @TenantId then delete;

	declare @rf table(Id nvarchar(16), [Order] int, [Type] nvarchar(16), [Url] nvarchar(255), [Name] nvarchar(255));
	insert into @rf (Id, [Type], [Order], [Url], [Name]) values
		(N'acc.date',  N'by.account',  1, N'/reports/account/rto_accdate', N'Обороти рахунку (дата)'),
		(N'acc.agent', N'by.account',  2, N'/reports/account/rto_accagent', N'Обороти рахунку (контрагент)'),
		(N'acc.item',  N'by.account',  3, N'/reports/stock/rto_items', N'Оборотно сальдова відомість (об''єкт обліку)'),
		(N'plan.turnover', N'by.plan', 1, N'/reports/plan/turnover',  N'Оборотно сальдова відомість'),
		(N'plan.money',    N'by.plan', 2, N'/reports/plan/cashflow',  N'Відомість по грошових коштах');

	merge rep.RepFiles as t
	using @rf as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Url] = s.[Url],
		t.[Order] = s.[Order],
		t.[Type] = s.[Type]
	when not matched by target then insert
		(TenantId, Id, [Name], [Type], [Order], [Url]) values
		(@TenantId, s.Id, s.[Name], s.[Type], [Order], [Url])
	when not matched by source and t.TenantId = @TenantId then delete;
end
go
-------------------------------------------------
-- FormsMenu
create or alter procedure ini.[Forms.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	declare @fu table(Id nvarchar(32), [Order] int, Category nvarchar(32), [Name] nvarchar(255));
	insert into @fu (Id, [Order], [Category], [Name]) values
		(N'Sales.Order',   10, N'@[Sales]', N'@[Orders]'),
		(N'Sales.Sales',   11, N'@[Sales]', N'@[Sales]'),
		(N'Sales.Payment', 12, N'@[Sales]', N'@[Payment]'),
		--
		(N'Purchase.Purchase', 20, N'@[Purchases]',  N'@[Purchase]'),
		(N'Purchase.Stock',    21, N'@[Purchases]',  N'@[Warehouse]'),
		(N'Purchase.Payment',  22, N'@[Purchases]',  N'@[Payment]'),
		--
		(N'Accounting.Bank',   30, N'@[Accounting]', N'@[Bank]'),
		(N'Accounting.Cash',   31, N'@[Accounting]', N'@[CashAccount]');
	merge doc.FormsMenu as t
	using @fu as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.Category = s.Category
	when not matched by target then insert
		(TenantId, Id, [Name], [Order], Category) values
		(@TenantId, s.Id, s.[Name], [Order], Category)
	when not matched by source and t.TenantId = @TenantId then delete;

	-- forms
	declare @df table(id nvarchar(16), [order] int, [name] nvarchar(255));
	insert into @df (id, [order], [name]) values
		-- Sales
		(N'invoice',    1, N'Замовлення клієнта'),
		(N'complcert',  2, N'Акт виконаних робіт'),
		-- 
		(N'waybillin',  3, N'Надходшення запасів'),
		(N'waybillout', 3, N'Видаткова накладна'),
		--
		(N'payout',    4, N'Витрата безготівкових коштів'),
		(N'payin',     5, N'Надходження безготівкових коштів'),
		(N'cashin',    6, N'Надходження готівки'),
		(N'cashout',   7, N'Витрата готівки'),
		-- 
		(N'manufact',  8, N'Виробничий акт-звіт');

	merge doc.Forms as t
	using @df as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order]
	when not matched by target then insert
		(TenantId, Id, [Order], [Name]) values
		(@TenantId, s.id, s.[order], s.[name])
	when not matched by source and t.TenantId = @TenantId then delete;

	-- form row kinds
	declare @rk table(Id nvarchar(16), [Order] int, Form nvarchar(16), [Name] nvarchar(255));
	insert into @rk([Form], [Order], Id, [Name]) values
	(N'waybillout', 1, N'', N'Всі рядки'),
	(N'waybillin',  1, N'', N'Всі рядки'),
	(N'payin',      1, N'', N'Немає рядків'),
	(N'payout',     1, N'', N'Немає рядків'),
	(N'cashin',     1, N'', N'Немає рядків'),
	(N'cashout',    1, N'', N'Немає рядків'),
	(N'invoice',    1, N'', N'Всі рядки'),
	(N'manufact',   2, N'Stock', N'Запаси'),
	(N'manufact',   3, N'Product', N'Продукція');

	merge doc.FormRowKinds as t
	using @rk as s on t.Id = s.Id and t.Form = s.Form and t.TenantId = @TenantId
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Order] = s.[Order]
	when not matched by target then insert
		(TenantId, Id, [Form], [Name], [Order]) values
		(@TenantId, s.Id, s.[Form], s.[Name], s.[Order])
	when not matched by source and t.TenantId = @TenantId then delete;

end
go
------------------------------------------------
exec ini.[Cat.OnCreateTenant] @TenantId = 1;
exec ini.[Forms.OnCreateTenant] @TenantId = 1;
exec ini.[Rep.OnCreateTenant] @TenantId = 1;
go




/*
initial catalog
*/
-- currencies
------------------------------------------------
begin
set nocount on;

declare @crc table(Id bigint, [Alpha3] nchar(3), [Number3] nchar(3), [Symbol] nvarchar(3), [Denom] int, [Name] nvarchar(255));

insert into @crc (Id, Alpha3, Number3, [Symbol], Denom, [Name]) values
(980, N'UAH', N'980', N'₴', 1, N'Українська гривня'),
(840, N'USD', N'840', N'$', 100, N'Долар США'),
(978, N'EUR', N'978', N'€', 100, N'Євро'),
(826, N'USD', N'826', N'£', 100, N'Британський фунт стерлінгов'),
(756, N'CHF', N'756', N'₣', 100, N'Швейцарський франк'),
(985, N'PLN', N'985', N'Zł',100, N'Польський злотий');

merge cat.Currencies as t
using @crc as s on t.Id = s.Id and t.TenantId = 0
when matched then update set
	t.[Alpha3] = s.[Alpha3],
	t.[Number3] = s.[Number3],
	t.[Symbol] = s.[Symbol],
	t.Denom = s.Denom,
	t.[Name] = s.[Name]
when not matched by target then insert
	(TenantId, Id, Alpha3, Number3, [Symbol], Denom, [Name]) values
	(0, s.Id, s.Alpha3, s.Number3, s.[Symbol], s.Denom, s.[Name])
when not matched by source and t.TenantId = 0 then delete;
end
go

