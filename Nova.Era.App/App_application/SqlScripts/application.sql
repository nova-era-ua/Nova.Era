/*
version: 10.1.1040
generated: 17.06.2023 11:16:56
*/


/* SqlScripts/application.sql */

/*
Copyright © 2008-2023 Oleksandr Kukhtin

Last updated : 05 feb 2023
module version : 7918
*/
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'a2sys')
	exec sp_executesql N'create schema a2sys';
go
------------------------------------------------
grant execute on schema::a2sys to public;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'Versions')
create table a2sys.Versions
(
	Module sysname not null constraint PK_Versions primary key,
	[Version] int null,
	[Title] nvarchar(255),
	[File] nvarchar(255)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'SysParams')
create table a2sys.SysParams
(
	Name sysname not null constraint PK_SysParams primary key,
	StringValue nvarchar(255) null,
	IntValue int null,
	DateValue datetime null
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2sys' and DOMAIN_NAME=N'Id.TableType' and DATA_TYPE=N'table type')
	create type a2sys.[Id.TableType]
	as table(
		Id bigint null
	);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2sys' and DOMAIN_NAME=N'GUID.TableType' and DATA_TYPE=N'table type')
	create type a2sys.[GUID.TableType]
	as table(
		Id uniqueidentifier null
	);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2sys' and DOMAIN_NAME=N'NameValue.TableType' and DATA_TYPE=N'table type')
create type a2sys.[NameValue.TableType]
as table(
	[Name] nvarchar(255),
	[Value] nvarchar(max)
);
go
------------------------------------------------
create or alter procedure a2sys.[GetVersions]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Module], [Version], [File], [Title] from a2sys.Versions;
end
go
------------------------------------------------
create or alter procedure a2sys.[SetVersion]
@Module nvarchar(255),
@Version int
as
begin
	set nocount on;
	set transaction isolation level read committed;
	if not exists(select * from a2sys.Versions where Module = @Module)
		insert into a2sys.Versions (Module, [Version]) values (@Module, @Version);
	else
		update a2sys.Versions set [Version] = @Version where Module = @Module;
end
go

------------------------------------------------
create or alter procedure a2sys.[AppTitle.Load]
as
begin
	set nocount on;
	select [AppTitle], [AppSubTitle]
	from (select Name, Value=StringValue from a2sys.SysParams) as s
		pivot (min(Value) for Name in ([AppTitle], [AppSubTitle])) as p;
end
go

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
	SetPassword bit,
	UtcDateCreated datetime not null constraint DF_Users_UtcDateCreated default(getutcdate()),
	constraint PK_Users primary key (Tenant, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'appsec' and TABLE_NAME=N'Users' and COLUMN_NAME=N'SetPassword')
	alter table appsec.Users add SetPassword bit;
go
------------------------------------------------
create or alter view appsec.ViewUsers
as
	select Id, UserName, DomainUser, PasswordHash, SecurityStamp, Email, PhoneNumber,
		LockoutEnabled, AccessFailedCount, LockoutEndDateUtc, TwoFactorEnabled, [Locale],
		PersonName, Memo, Void, LastLoginDate, LastLoginHost, Tenant, EmailConfirmed,
		PhoneNumberConfirmed, RegisterHost, ChangePasswordEnabled, Segment,
		SecurityStamp2, PasswordHash2, SetPassword
	from appsec.Users u
	where Void=0 and Id <> 0;
go
------------------------------------------------
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

	update appsec.ViewUsers set PasswordHash = @PasswordHash, SecurityStamp = @SecurityStamp, SetPassword = null where Id=@Id;
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
create or alter procedure appsec.[User.SetPasswordHash]
@Id bigint,
@PasswordHash nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update appsec.ViewUsers set PasswordHash2 = @PasswordHash where Id = @Id;
end
go
------------------------------------------------
create or alter procedure appsec.[User.SetSecurityStamp]
@Id bigint,
@SecurityStamp nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update appsec.ViewUsers set SecurityStamp2 = @SecurityStamp where Id = @Id;
end
go
------------------------------------------------
create or alter procedure appsec.[User.SetPhoneNumberConfirmed]
@Id bigint,
@PhoneNumber nvarchar(255),
@Confirmed bit
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update appsec.ViewUsers set PhoneNumber = @PhoneNumber, PhoneNumberConfirmed = @Confirmed where Id = @Id;
end
go
------------------------------------------------
create or alter procedure appsec.[User.ChangePassword.Load]
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
------------------------------------------------
create or alter procedure appsec.[User.Simple.Create]
@Tenant int = 1,
@UserName nvarchar(255),
@PersonName nvarchar(255),
@PhoneNumber nvarchar(255),
@Email nvarchar(255),
@RegisterHost nvarchar(255),
@Locale nvarchar(255) = null,
@Segment nvarchar(255) = null,
@Memo nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rt table(Id bigint);
	insert into appsec.Users (Tenant, Segment, UserName, PersonName, PhoneNumber, Email, Memo, RegisterHost,
		EmailConfirmed, SecurityStamp, PasswordHash)
	output inserted.Id into @rt(Id)
	values (@Tenant, @Segment, @UserName, @PersonName, @PhoneNumber, @Email, @Memo, @RegisterHost,
		1, N'', N'');

	declare @id bigint;
	select top(1) @id = Id from @rt;

	select * from appsec.ViewUsers where Id = @id;
end
go
------------------------------------------------
create or alter procedure appsec.[UserStateInfo.Load]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [UserState!TUserState!Object] = null, License = N'LICENSE TEXT HERE';
end
go



-- security schema
------------------------------------------------
create or alter procedure appsec.SetTenantId
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
------------------------------------------------
create or alter procedure appsec.[TenantUser.Simple.Create]
@Id bigint,
@Tenant int,
@UserName nvarchar(255),
@PersonName nvarchar(255),
@PhoneNumber nvarchar(255),
@Email nvarchar(255),
@RegisterHost nvarchar(255),
@Locale nvarchar(255) = null,
@Segment nvarchar(255) = null,
@Memo nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rt table(Id bigint);
	insert into appsec.Users (Id, Tenant, Segment, UserName, PersonName, PhoneNumber, Email, Memo, RegisterHost,
		EmailConfirmed, SecurityStamp, PasswordHash)
	output inserted.Id into @rt(Id)
	values (@Id, @Tenant, @Segment, @UserName, @PersonName, @PhoneNumber, @Email, @Memo, @RegisterHost,
		1, N'', N'');
end
go

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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Tags')
	create sequence cat.SQ_Tags as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Tags')
create table cat.Tags
(
	TenantId int not null,
	Id bigint not null
		constraint DF_Tags_Id default(next value for cat.SQ_Tags),
	[For] nvarchar(32) not null,
	Void bit not null 
		constraint DF_Tags_Void default(0),
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Memo] nvarchar(255),
		constraint PK_Tags primary key (TenantId, Id)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'TagsAgent')
create table cat.TagsAgent
(
	TenantId int not null,
	Tag bigint not null,
	Agent bigint not null
		constraint PK_TagAgents primary key (TenantId, Tag, Agent),
		constraint FK_TagAgents_Tag_Tags foreign key (TenantId, Tag) references cat.Tags(TenantId, Id),
		constraint FK_TagAgents_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id)
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
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'crm' and TABLE_NAME=N'TagsLead')
create table crm.TagsLead
(
	TenantId int not null,
	Tag bigint not null,
	[Lead] bigint not null
		constraint PK_TagsLeads primary key (TenantId, Tag, [Lead]),
		constraint FK_TagsLeads_Tag_Tags foreign key (TenantId, Tag) references cat.Tags(TenantId, Id),
		constraint FK_TagsLeads_Lead_Leads foreign key (TenantId, [Lead]) references crm.Leads(TenantId, Id)
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
	Category nvarchar(64),
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
		constraint DF_TaskStates_Id default(next value for app.SQ_TaskStates),
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
	LinkType nvarchar(64),
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

-- MIGRATIONS
------------------------------------------------
drop procedure if exists cat.[CashAccount.GetRem];
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Countries' and COLUMN_NAME=N'Alpha3')
	alter table cat.Countries add [Alpha3] nchar(3);
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Countries' and COLUMN_NAME=N'Aplha3')
	alter table cat.Countries drop column [Aplha3];
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items' and COLUMN_NAME=N'Country')
	alter table cat.Items add Country nchar(3); -- references cat.Countries
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Items' and CONSTRAINT_NAME = N'FK_Items_Country_Countries')
	alter table cat.Items add 
		constraint FK_Items_Country_Countries foreign key (TenantId, Country) references cat.Countries(TenantId, Code);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Companies' and COLUMN_NAME=N'AutonumPrefix')
	alter table cat.Companies add [AutonumPrefix] nvarchar(8);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations' and COLUMN_NAME=N'Autonum')
	alter table doc.Operations add Autonum bigint; -- references doc.Autonums
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Operations' and CONSTRAINT_NAME = N'FK_Operations_Autonum_Autonums')
	alter table doc.Operations add 
		constraint FK_Operations_Autonum_Autonums foreign key (TenantId, Autonum) references doc.Autonums(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'No')
	alter table doc.Documents add [No] nvarchar(64);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Autonums' and COLUMN_NAME=N'Uid')
	alter table doc.Autonums add [Uid] uniqueidentifier not null
		constraint DF_Autonum_Uid default(newid()) with values;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal' and COLUMN_NAME=N'CostItem')
begin
	alter table jrn.StockJournal add CostItem bigint;
	alter table jrn.StockJournal add RespCenter bigint;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_SCHEMA = N'jrn' and TABLE_NAME = N'StockJournal' and CONSTRAINT_NAME = N'FK_StockJournal_CostItem_CostItems')
begin
	alter table jrn.StockJournal add constraint FK_StockJournal_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id);
	alter table jrn.StockJournal add constraint FK_StockJournal_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal' and COLUMN_NAME=N'Agent')
begin
	alter table jrn.StockJournal add Agent bigint null;
	alter table jrn.StockJournal add [Contract] bigint null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_SCHEMA = N'jrn' and TABLE_NAME = N'StockJournal' and CONSTRAINT_NAME = N'FK_StockJournal_Agent_Agents')
begin
	alter table jrn.StockJournal add constraint 
		FK_StockJournal_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id);
	alter table jrn.StockJournal add constraint 
		FK_StockJournal_Contract_Contracts foreign key (TenantId, [Contract]) references doc.Contracts(TenantId, Id);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Companies' and COLUMN_NAME=N'Logo')
	alter table cat.Companies add Logo bigint null
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Companies' and CONSTRAINT_NAME = N'FK_Companies_Logo_Blobs')
	alter table cat.Companies add constraint 
		FK_Companies_Logo_Blobs foreign key (TenantId, Logo) references app.Blobs(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpTrans' and COLUMN_NAME=N'Factor')
	alter table doc.OpTrans add Factor smallint -- 1 normal, -1 storno
		constraint CK_OpTrans_Factor check (Factor in (1, -1))
		constraint DF_OpTrans_Factor default (1) with values;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'Journal' and COLUMN_NAME=N'Project')
	alter table jrn.Journal	add Project bigint null,
		constraint FK_Journal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'Journal' and COLUMN_NAME=N'Operation')
	alter table jrn.Journal	add Operation bigint null,
		constraint FK_Journal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'Project')
	alter table doc.Documents add Project bigint null,
		constraint FK_Documents_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal' and COLUMN_NAME=N'Project')
	alter table jrn.StockJournal add Project bigint,
		constraint FK_StockJournal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'CashJournal' and COLUMN_NAME=N'Project')
	alter table jrn.CashJournal add Project bigint,
		constraint FK_CashJournal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal' and COLUMN_NAME=N'Operation')
	alter table jrn.StockJournal add Operation bigint,
		constraint FK_StockJournal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'CashJournal' and COLUMN_NAME=N'Operation')
	alter table jrn.CashJournal add Operation bigint,
		constraint FK_CashJournal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations' and COLUMN_NAME=N'Kind')
	alter table doc.Operations add [Kind] nvarchar(16),
		constraint FK_Operations_Kind_OperationKinds foreign key (TenantId, Kind) references doc.OperationKinds(TenantId, Id);
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations' and COLUMN_NAME=N'Agent')
begin
	alter table doc.Operations drop column Agent;
	alter table doc.Operations drop column WarehouseFrom;
	alter table doc.Operations drop column WarehouseTo;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OperationKinds' and COLUMN_NAME=N'LinkType')
	alter table doc.OperationKinds add LinkType nchar(1);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'BindKind')
begin
	alter table doc.Documents add BindKind nvarchar(16);
	alter table doc.Documents add BindFactor smallint;
end
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'ReconcileFactor')
begin
	alter table doc.Documents drop column ReconcileFactor;
	alter table doc.Documents drop column [Reconcile];
end
go
------------------------------------------------
drop table if exists jrn.Reconcile;
drop sequence if exists jrn.SQ_Reconcile;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'crm' and TABLE_NAME=N'LeadStages' and COLUMN_NAME=N'Memo')
	alter table crm.LeadStages add [Memo] nvarchar(255);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'crm' and TABLE_NAME=N'LeadStages' and COLUMN_NAME=N'Kind')
	alter table crm.LeadStages add [Kind] nchar(1);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Contacts' and COLUMN_NAME=N'Email')
begin
	alter table cat.Contacts add Email nvarchar(64);
	alter table cat.Contacts add Phone nvarchar(32);
	alter table cat.Contacts add [Address] nvarchar(255);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Forms' and COLUMN_NAME=N'HasState')
	alter table doc.Forms add HasState bit;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'State')
	alter table doc.Documents add [State] bigint,
		constraint FK_Documents_State_DocStates foreign key (TenantId, [State]) references doc.DocStates(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items' and COLUMN_NAME=N'Parent')
	alter table cat.Items add Parent bigint,
		constraint FK_Items_Parent_Items foreign key (TenantId, [Parent]) references cat.Items(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items' and COLUMN_NAME=N'Variant')
	alter table cat.Items add Variant bigint,
		constraint FK_Items_Variant_ItemVariants foreign key (TenantId, Variant) references cat.ItemVariants(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items' and COLUMN_NAME=N'IsVariant')
	alter table cat.Items add IsVariant as (cast(case when [Parent] is not null then 1 else 0 end as bit));
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Tasks' and COLUMN_NAME=N'LinkType')
	alter table app.Tasks add LinkType nvarchar(64);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'app' and TABLE_NAME=N'Widgets' and COLUMN_NAME=N'Category')
	alter table app.Widgets add Category nvarchar(64);
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
	if @Id = -1 
		set @name = N'@[Placeholder.AllWarehouses]';
	else if @Id is not null and @Id <> -1
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
	if @Id = -1
		set @name = N'@[Placeholder.AllCompanies]';
	else if @Id is not null
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
	if @Id = -1 
		set @name = N'@[Placeholder.AllAccounts]';
	else if @Id is not null
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
------------------------------------------------
create or alter function cat.fn_GetItemBreadcrumbs(@TenantId int, @Id bigint, @sep nvarchar(32) = null)
returns nvarchar(max)
as
begin
	set @sep = isnull(@sep, N' > ');
	declare @path nvarchar(max);
	with T(Id, Parent, [Level]) as (
		select Id, Parent, 0 from cat.ItemTree where TenantId = @TenantId and Id = @Id
		union all 
		select it.Id, it.Parent, [Level] = T.[Level] + 1 
			from T inner join cat.ItemTree it on it.TenantId = @TenantId and it.Id = T.Parent
		where it.Id <> it.[Root] and it.TenantId = @TenantId
	)
	select @path = string_agg([Name], @sep) within group (order by T.[Level] desc)
	from T inner join cat.ItemTree it on it.TenantId = @TenantId and T.Id = it.Id 
	return @path;
end
go
------------------------------------------------
create or alter function rep.fn_MakeRepId2(@Id1 bigint, @Id2 bigint)
returns nvarchar(64)
as
begin
	return cast(@Id1 as nvarchar(31)) + N'_'+ cast(@Id2 as nvarchar(31));
end
go
------------------------------------------------
create or alter function rep.fn_FoldSaldo(@DtCt smallint, @Dt money, @Ct money)
returns money
as
begin
	declare @e money = @Dt - @Ct;
	declare @r money;
	if @DtCt = 1
		set @r = iif(@e < 0, 0, @e);
	else if @DtCt = -1
		set @r = iif(@e < 0, -@e, 0);
	return @r;
end
go
------------------------------------------------
create or alter function doc.fn_getDocumentRems(@CheckRems bit, @TenantId int, @Document bigint)
returns @rems table (Item bigint, Rem float, [Role] bigint)
as
begin
	if @CheckRems = 0
		return;
	declare @date date;
	declare @wh bigint;
	declare @check nchar(1);
	declare @plan bigint;
	select @check = CheckRems, @plan = AccPlanRems from app.Settings where TenantId = @TenantId;
	select @date = [Date], @wh = WhFrom from doc.Documents where TenantId = @TenantId and Id=@Document;
	if @check = N'A' and @plan is not null
	begin
		with A as (
			select a.Id, ra.[Role] from acc.Accounts a
			left join cat.ItemRoleAccounts ra on a.Id = ra.Account and a.TenantId = ra.TenantId and a.[Plan] = ra.[Plan]
			where a.TenantId = @TenantId and Void = 0 and IsItem = 1 and IsWarehouse = 1 and a.[Plan] = @plan
		)
		insert into @rems(Item, Rem, [Role])
		select j.Item, Rem = sum(j.Qty * j.DtCt), A.[Role]
		from jrn.Journal j inner join A on j.Account = A.Id and j.TenantId = @TenantId
		where j.Item in (select Item from doc.DocDetails dd where dd.TenantId = @TenantId and dd.Document = @Document)
			and j.Warehouse = @wh
		group by j.Item, A.[Role];
	end
	return;
end
go
------------------------------------------------
create or alter function doc.fn_getItemsRems(@CheckRems bit, @TenantId int, @Items a2sys.[Id.TableType] readonly, @Date date, @Wh bigint)
returns @rems table (Item bigint, Rem float, [Role] bigint)
as
begin
	if @CheckRems = 0
		return;
	declare @check nchar(1);
	declare @plan bigint;
	select @check = CheckRems, @plan = AccPlanRems from app.Settings where TenantId = @TenantId;
	if @check = N'A' and @plan is not null
	begin
		with TA as (
			select a.Id, ra.[Role] from acc.Accounts a
				left join cat.ItemRoleAccounts ra on a.Id = ra.Account and a.TenantId = ra.TenantId and a.[Plan] = ra.[Plan]
			where a.TenantId = @TenantId and Void = 0 and IsItem = 1 and IsWarehouse = 1 and a.[Plan] = @plan
		)
		insert into @rems(Item, Rem, [Role])
		select j.Item, Rem = sum(j.Qty * DtCt), TA.[Role]
		from jrn.Journal j 
			inner join TA on j.Account = TA.Id
		where j.TenantId = @TenantId and j.[Date] <= @Date and j.Warehouse = @Wh
			and j.Item in (select Id from @Items)
		group by j.Item, TA.[Role];
	end
	return;
end
go
------------------------------------------------
create or alter function doc.fn_getOneItemRem(@TenantId int, @Item bigint, @Role bigint, @Date date, @Wh bigint)
returns float
as
begin
	declare @check nchar(1);
	declare @plan bigint;
	select @check = CheckRems, @plan = AccPlanRems from app.Settings where TenantId = @TenantId;
	declare @rem float = 0;
	if @check = N'A' and @plan is not null
	begin
		with TA as (
			select a.Id from acc.Accounts a
				left join cat.ItemRoleAccounts ra on a.Id = ra.Account and a.TenantId = ra.TenantId and a.[Plan] = ra.[Plan] and ra.[Role] = @Role
			where a.TenantId = @TenantId and Void = 0 and IsItem = 1 and IsWarehouse = 1 and a.[Plan] = @plan
		)
		select @rem = sum(j.Qty * DtCt)
		from jrn.Journal j 
			inner join TA on j.Account = TA.Id
		where j.TenantId = @TenantId and j.[Date] <= @Date and j.Warehouse = @Wh
			and j.Item = @Item
	end
	return @rem;
end
go
------------------------------------------------
create or alter function app.fn_IsCheckRems(@TenantId int, @CheckRems bit)
returns bit
as
begin
	declare @retval bit = @CheckRems;
	if @CheckRems = 1 and N'' = isnull((select CheckRems from app.Settings where TenantId = @TenantId), N'')
		set @retval = 0;
	return @retval;
end
go
------------------------------------------------
create or alter function rep.fn_getCashAccountRem(@TenantId int, @CashAccount bigint, @Date date)
returns money
as
begin
	declare @result money;
	set @Date = isnull(@Date, getdate());
	select @result = sum([Sum] * InOut) from jrn.CashJournal 
		where TenantId = @TenantId and CashAccount = @CashAccount and [Date] <= @Date;
	return @result;
end
go

/*
user interface
*/
drop procedure if exists ui.[MenuModule.Merge];
drop procedure if exists ui.[Catalog.Merge];
drop type if exists ui.[MenuModule.TableType];
drop type if exists ui.[Catalog.TableType];
go
-------------------------------------------------
create type ui.[MenuModule.TableType] as table
(
	Id bigint,
	Parent bigint,
	[Name] nvarchar(255),
	[Url] nvarchar(255),
	Icon nvarchar(255),
	[Model] nvarchar(255),
	[Order] int,
	[Description] nvarchar(255),
	[Help] nvarchar(255),
	Module nvarchar(16),
	ClassName nvarchar(255)
);
go
-------------------------------------------------
create type ui.[Catalog.TableType] as table (
	Id int, 
	Menu nvarchar(16), 
	[Name] nvarchar(255), 
	[Order] int, 
	Category nvarchar(32), 
	[Memo] nvarchar(255), 
	[Url] nvarchar(255), 
	Icon nvarchar(16)
);
-------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'ui' and TABLE_NAME=N'Catalog')
create table ui.[Catalog]
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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'ui' and SEQUENCE_NAME=N'SQ_Menu')
	create sequence ui.SQ_Menu as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'ui' and TABLE_NAME=N'Menu')
create table ui.Menu
(
	Id	bigint not null constraint PK_Menu primary key
		constraint DF_Menu_PK default(next value for ui.SQ_Menu),
	Parent bigint null
		constraint FK_Menu_Parent_Menu foreign key references ui.Menu(Id),
	[Key] nchar(4) null,
	[Name] nvarchar(255) null,
	[Url] nvarchar(255) null,
	Icon nvarchar(255) null,
	Model nvarchar(255) null,
	Help nvarchar(255) null,
	[Order] int not null constraint DF_Menu_Order default(0),
	[Description] nvarchar(255) null,
	[Params] nvarchar(255) null,
	[Feature] nchar(4) null,
	[Feature2] nvarchar(255) null,
	[ClassName] nvarchar(255) null	
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
set nocount on;
if not exists(select * from a2sys.SysParams where [Name] = N'AppTitle')
	insert into a2sys.SysParams ([Name], StringValue) values (N'AppTitle', N'Нова Ера');
else
	update a2sys.SysParams set StringValue = N'Нова Ера' where [Name] = N'AppTitle';
go
------------------------------------------------
create procedure ui.[MenuModule.Merge]
@Menu ui.[MenuModule.TableType] readonly,
@Start bigint,
@End bigint
as
begin
	with T as (
		select * from ui.Menu where Id >=@Start and Id <= @End
	)
	merge T as t
	using @Menu as s
	on t.Id = s.Id 
	when matched then
		update set
			t.Id = s.Id,
			t.Parent = s.Parent,
			t.[Name] = s.[Name],
			t.[Url] = s.[Url],
			t.[Icon] = s.Icon,
			t.[Order] = s.[Order],
			t.Model = s.Model,
			t.[Description] = s.[Description],
			t.Help = s.Help,
			t.ClassName = s.ClassName
	when not matched by target then
		insert(Id, Parent, [Name], [Url], Icon, [Order], Model, [Description], Help, ClassName) values 
		(Id, Parent, [Name], [Url], Icon, [Order], Model, [Description], Help, ClassName)
	when not matched by source and t.Id >= @Start and t.Id < @End then 
		delete;
end
go
------------------------------------------------
create or alter procedure ui.[Catalog.Merge]
@Catalog ui.[Catalog.TableType] readonly,
@Start bigint,
@End bigint
as
begin
	set nocount on;
	with T as (
		select * from ui.[Catalog] where Id >=@Start and Id <= @End
	)
	merge T as t
	using @Catalog as s
	on t.Id = s.Id 
	when matched then
		update set
			t.Menu = s.Menu,
			t.[Name] = s.[Name],
			t.[Url] = s.[Url],
			t.[Icon] = s.Icon,
			t.[Order] = s.[Order],
			t.Category = s.Category,
			t.[Memo] = s.[Memo]
	when not matched by target then
		insert(Id, [Menu], [Name], [Url], Icon, [Order], Category, Memo) values 
		(Id, [Menu], [Name], [Url], Icon, [Order], Category, Memo)
	when not matched by source and t.Id >= @Start and t.Id < @End then 
		delete;
end
go
------------------------------------------------
create or alter procedure ui.[Menu.Simple.User.Load]
@TenantId int = 1,
@UserId bigint = null,
@Mobile bit = 0,
@Root bigint = 1
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with RT as (
		select Id=m0.Id, ParentId = m0.Parent, [Level]=0
			from ui.Menu m0
			where m0.Id = @Root
		union all
		select m1.Id, m1.Parent, RT.[Level]+1
			from RT inner join ui.Menu m1 on m1.Parent = RT.Id
	)
	select [Menu!TMenu!Tree] = null, [Id!!Id]=RT.Id, [!TMenu.Menu!ParentId]=RT.ParentId,
		[Menu!TMenu!Array] = null,
		m.Name, m.Url, m.Icon, m.[Description], m.Help, m.Params, m.ClassName
	from RT 
		inner join ui.Menu m on RT.Id=m.Id
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

	declare @menu ui.[MenuModule.TableType];

	insert into @menu(Id, Parent, [Order], [Name], [Url], Icon, ClassName) 
	values
		(1,  null,  0, N'Main',         null,         null, null),
		(2,  null,  0, N'Start',         null,         null, null),
		(3,  null,  0, N'Init',      null,         null, null),

		(71,    2,  1, N'@[Welcome]',     N'appstart',   N'success-outline', null),
		(72,    3,  1, N'@[AppInit]',     N'appinit',    N'arrow-up', null),

		(10,    1,  10, N'@[Dashboard]',     N'dashboard',   N'dashboard-outline', null),
		(14,    1,  11, N'@[Tasks]',         N'task',        N'task-complete', null),
		(15,    1,  12, N'@[Crm]',           N'crm',         N'share', null),
		(20,    1,  20, N'@[Sales]',         N'sales',       N'shopping', N'border-top'),
		(21,    1,  21, N'@[Purchases]',     N'purchase',    N'cart', null),
		(50,    1,  50, N'@[Accounting]',    N'accounting',  N'calc', null),
		--(14,    1,  16, N'@[Manufacturing]', N'$manufacturing',  N'wrench', null),
		--(16,    1,  17, N'@[Payroll]',       N'payroll',  N'calc', null),
		--(17,    1,  18, N'@[Tax]',           N'tax',  N'calc', null),
		(88,    1,  880, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
		(90,    1,  900, N'@[Profile]',        N'profile',   N'user', null),
		-- TASKS
		(1401,  14, 10, N'@[Board]',          N'kanban',    N'dashboard-outline', null),
		-- CRM
		(1101,  15, 11, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		(1102,  15, 12, N'@[Leads]',          N'lead',      N'users', N'border-top'),
		(1103,  15, 13, N'@[Contacts]',       N'contact',   N'address-card', null),
		(110,   15, 14, N'@[Catalogs]',       null,  null, null),
		(1105, 110, 15, N'@[Agents]',         N'agent',     N'users', null),
		(1106, 110, 16, N'@[CatalogOther]',   N'catalog',   N'list', null),
		-- Sales
		(1201,   20, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(120,    20, 11, N'@[Documents]',      null,  null, null),
		(1202,   120, 2, N'@[Orders]',         N'order',     N'task-complete', null),
		(1203,   120, 3, N'@[Sales]',          N'sales',     N'shopping', null),
		(1204,   120, 4, N'@[Payment]',        N'payment',   N'currency-uah', null),
		(121,    20, 12, N'@[PriceLists]', null, null, null),
		(1210,	 121, 11, N'@[Prices]',         N'price',     N'tag-outline', null),
		(122,    20, 12, N'@[Catalogs]',      null,  null, null),
		(1220,   122, 30, N'@[Customers]',      N'agent',     N'users', null),
		(1221,   122, 31, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1222,   122, 32, N'@[Projects]',       N'project',   N'log', null),
		(1223,   122, 33, N'@[Items]',          N'item',      N'package-outline', N'line-top'),
		(1224,   122, 34, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1230,   20, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1231,   20, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Purchase
		(1301,   21, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(130,    21, 11, N'@[Documents]',      null,  null, null),
		(1302,  130, 10, N'@[Purchases]',      N'purchase',  N'cart', null),
		(1303,  130, 11, N'@[Warehouse]',      N'stock',     N'warehouse', null),
		(1304,  130, 12, N'@[Payment]',        N'payment',   N'currency-uah', null),
		--(1310,   14, 20, N'@[Planning]',       N'plan',      N'calendar', N'border-top'),
		--(131,    14, 12, N'@[Prices]', null, null, null),
		--(1311,  131, 10, N'@[PriceDoc]',       N'pricedoc',  N'file', null),
		--(1312,  131, 11, N'@[Prices]',         N'price',     N'tag-outline', null),
		(133,    21, 14, N'@[Catalogs]',  null, null, null),
		(1320,  133, 10, N'@[Suppliers]',      N'agent',     N'users', null),
		(1321,  133, 11, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1322,  133, 12, N'@[Items]',          N'item',      N'package-outline', N'line-top'),
		(1323,  133, 13, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1330,   21, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1331,   21, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Accounting
		(1501,   50, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(150,    50, 11, N'@[Documents]',      null, null, null),
		(1502,  150, 10, N'@[Bank]',           N'bank',   N'bank',  null),
		(1503,  150, 11, N'@[CashAccount]',    N'cash',   N'currency-uah',  null),
		(1504,   50, 12, N'@[AccountPlans]',   N'plan',      N'account',  N'border-top'),
		(153,    50, 15, N'@[Catalogs]',  null, null, null),
		(1505,  153, 10, N'@[BankAccounts]',   N'bankacc',   N'bank', null),
		(1506,	153, 11, N'@[CashAccounts]',   N'cashacc',   N'currency-uah', null),
		(1507,  153, 12, N'@[Agents]',         N'agent',     N'users', null),
		(1508,  153, 13, N'@[Persons]',        N'person',    N'user-role', null),
		(1509,  153, 14, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1510,  153, 15, N'@[Projects]',       N'project',   N'log', null),
		(1511,  153, 16, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1512,   50, 20, N'@[Journal]',        N'journal',   N'file-content',  N'border-top'),
		(1530,   50, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1531,   50, 41, N'@[Service]',        N'service',   N'gear-outline', null),

		-- Settings
		(881,   88, 11, N'@[Settings]',     null, null, null),
		(8811, 881, 10, N'@[AccPolicy]',    N'policy',      N'gear-outline',  null),
		(8812, 881, 10, N'@[AccountPlans]', N'accountplan', N'account',  null),
		(8813, 881, 11, N'@[Operations]',   N'operation',   N'file-content', null),
		(882,   88, 12, N'@[Catalogs]',     null, null, null),
		(8821, 882, 11, N'@[Companies]',    N'company',   N'company', null),
		(8822, 882, 12, N'@[Warehouses]',   N'warehouse', N'warehouse', null),
		(8823, 882, 13, N'@[BankAccounts]', N'bankacc',   N'bank', null),
		(8824, 882, 14, N'@[CashAccounts]', N'cashacc',   N'currency-uah', null),
		(8825, 882, 15, N'@[Agents]',       N'agent',     N'users', N'line-top'),
		(8826, 882, 16, N'@[Persons]',      N'person',    N'user-role', null),
		(8827, 882, 17, N'@[Contracts]',    N'contract',  N'user-image', null),
		(8828, 882, 17, N'@[Projects]',     N'project',   N'log', null),
		(8829, 882, 18, N'@[Items]',        N'item',      N'package-outline', N'line-top'),
		(8830, 882, 19, N'@[CatalogOther]', N'catalog',   N'list', null),
		(884,   88, 14, N'@[Administration]', null, null, N'line-top'),
		(8841, 884, 20, N'@[Users]',        N'user',    N'user',  null),
		(885,   88, 15, N'@[Integrations]', 'integration',N'queue', N'border-top'),
		(8850,  88, 30, N'Розробка (debug)',N'develop',   N'switch', N'border-top'),
		(8851,  88, 99, N'Test',            N'test',      N'file', null),
		(8852,  88, 100, N'Test Group',     N'testgroup',      N'file', null),
		-- Profile
		(9001,  90, 10, N'@[Defaults]',    N'default',   N'list', null),
		(9002,  90, 20, N'@[License]',     N'license',   N'policy', null);

	exec ui.[MenuModule.Merge] @menu, 1, 9999;
end
go
-------------------------------------------------
-- Catalog
begin
	set nocount on;
	declare @cat ui.[Catalog.TableType];

	insert into @cat (Id, Menu, [Order], [Category], [Name], [Url], Icon, Memo) values

	(100, N'Sales', 10, N'@[Items]', N'@[Units]',         N'/catalog/unit/index',       N'list',  N''),
	(102, N'Sales', 11, N'@[Items]', N'@[Grouping.Item]', N'/catalog/itemgroup/index',  N'list',  N''),
	(103, N'Sales', 12, N'@[Items]', N'@[Variant.Setup]', N'/catalog/itemoption/index', N'list',  N''),
	--(102, N'Sales', 12, N'@[Items]', N'@[Brands]',   N'/catalog/brand/index', N'list',  N''),
	(105, N'Sales', 11, N'@[Prices]', N'@[PriceKinds]',   N'/catalog/pricekind/index', N'list',  N''),

	(200, N'Purchase',   10, N'@[Items]',  N'@[Units]',        N'/catalog/unit/index', N'list',  N''),
	(201, N'Purchase',   11, N'@[Items]',  N'@[Grouping.Item]', N'/catalog/itemgroup/index', N'list',  N''),
	(202, N'Purchase',   12, N'@[Prices]', N'@[PriceKinds]',   N'/catalog/pricekind/index', N'list',  N''),

	-- accounting
	(300, N'Accounting',  10, N'@[Accounting]', N'@[Banks]', N'/catalog/bank/index', N'list',  N''),
	(301, N'Accounting',  11, N'@[Accounting]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N''),
	(305, N'Accounting',  12, N'@[Items]',     N'@[Units]',      N'/catalog/unit/index', N'list',  N''),
	(306, N'Accounting',  13, N'@[Prices]',    N'@[PriceKinds]', N'/catalog/pricekind/index', N'list',  N''),

	-- crm
	(400, N'Crm',         10, N'@[Leads]',    N'@[LeadStages]',        N'/catalog/crm/leadstage/index', N'list',  N''),

	-- settings
	(900, N'Settings',  01, N'@[General]',   N'@[Countries]',   N'/catalog/country/index', N'list',  N''),
	(901, N'Settings',  02, N'@[General]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N''),
	(902, N'Settings',  03, N'@[General]',   N'@[RespCenters]', N'/catalog/respcenter/index', N'list',  N''),
	(910, N'Settings',  10, N'@[Accounts]',  N'@[ItemRoles]',   N'/catalog/itemrole/index', N'list',  N''),
	(911, N'Settings',  11, N'@[Accounts]',  N'@[AccKinds]',    N'/catalog/acckind/index', N'list',  N''),
	(915, N'Settings',  12, N'@[Documents]', N'@[Autonums]',    N'/catalog/autonum/index', N'list',  N''),
	(916, N'Settings',  13, N'@[Documents]', N'@[DocStates]',   N'/catalog/docstate/index', N'list',  N''),
	(920, N'Settings',  21, N'@[Accounting]', N'@[Banks]',         N'/catalog/bank/index', N'list',  N''),
	(922, N'Settings',  23, N'@[Accounting]', N'@[CostItems]',     N'/catalog/costitem/index', N'list',  N''),
	(923, N'Settings',  24, N'@[Accounting]', N'@[CashFlowItems]', N'/catalog/cashflowitem/index', N'list',  N''),
	(924, N'Settings',  25, N'@[Accounting]', N'@[Taxes]',         N'/catalog/taxes/index', N'list',  N''),
	(931, N'Settings',  31, N'@[Items]',  N'@[Grouping.Item]',     N'/catalog/itemgroup/index', N'list',  N''),
	(932, N'Settings',  32, N'@[Items]',  N'@[Categories]',        N'/catalog/itemcategory/index', N'list',  N''),
	(933, N'Settings',  33, N'@[Items]',  N'@[Units]',             N'/catalog/unit/index', N'list',  N''),
	(934, N'Settings',  34, N'@[Items]',  N'@[Brands]',            N'/catalog/brand/index', N'list',  N''),
	(945, N'Settings',  35, N'@[Items]',  N'@[Vendors]',           N'/catalog/vendor/index', N'list',  N''),
	(940, N'Settings',  40, N'@[Prices]', N'@[PriceKinds]',        N'/catalog/pricekind/index', N'list',  N''),
	(950, N'Settings',  50, N'@[Crm]',    N'@[LeadStages]',        N'/catalog/crm/leadstage/index', N'list',  N'');

	exec ui.[Catalog.Merge] @cat, 100, 999;
end
go
-------------------------------------------------
create or alter procedure ui.[Catalog.Other.Index]
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
	from ui.[Catalog]
	where Menu = @Menu order by [Order];
end
go
-------------------------------------------------
-- Integrations
begin
	set nocount on;
	declare @int table(Id int, [Key] nvarchar(16), [Name] nvarchar(255), [Order] int, 
		Category nvarchar(32), [Memo] nvarchar(255), [SetupUrl] nvarchar(255), DocumentUrl nvarchar(255),
		Icon nvarchar(16), Logo nvarchar(255));
	insert into @int (Id, [Key], [Order], [Category], [Name], [SetupUrl], DocumentUrl, Icon, Logo, Memo) values
	-- delivery services
	(1000, N'Delivery', 1000, N'@[Int.Delivery]', N'Нова пошта',    
		N'/integration/delivery/novaposhta/setup', N'/integration/delivery/novaposhta/document', 
		N'list',  N'/img/logo/np_logo.png', N'');

	merge app.[IntegrationSources] as t
	using @int as s on t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Key] = s.[Key],
		t.[Order] = s.[Order],
		t.Memo = s.Memo,
		t.[SetupUrl] = s.[SetupUrl],
		t.DocumentUrl = s.DocumentUrl,
		t.Logo = s.Logo,
		t.Icon = s.Icon
	when not matched by target then insert
		(Id,  [Key], [Name], [Order], Memo, [SetupUrl], DocumentUrl, Icon, Logo) values
		(s.Id, [Key], s.[Name], [Order], Memo, [SetupUrl], DocumentUrl, Icon, Logo)
	when not matched by source then delete;
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
		[RespCenter.Id!TRespCenter!Id] = d.RespCenter, [RespCenter.Name!TRespCenter!Name] = rc.[Name],
		[Period.From!TPeriod!] = isnull(d.PeriodFrom, getdate()), [Period.To!TPeriod!] = isnull(d.PeriodTo, getdate())
	from usr.Defaults d
		left join cat.Companies c on d.TenantId = c.TenantId and d.Company = c.Id
		left join cat.Warehouses w on d.TenantId = w.TenantId and d.Warehouse = w.Id
		left join cat.RespCenters rc on d.TenantId = rc.TenantId and d.RespCenter =rc.Id
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
create or alter procedure usr.[Default.SetRespCenter]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	exec usr.[Default.Ensure] @TenantId = @TenantId, @UserId = @UserId;
	update usr.Defaults set RespCenter = @Id where TenantId = @TenantId and UserId = @UserId;
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

-- DEBUG
------------------------------------------------
create or alter procedure app.[Policy.Load]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Policy!TPolicy!Object] = null, [Id!!Id] = 1, CheckRems, CheckPayments,
		[AccPlanRems!TAccount!RefId] = AccPlanRems,
		[AccPlanPayments!TAccount!RefId] = AccPlanPayments
	from app.Settings where TenantId = @TenantId;

	select [Accounts!TAccount!Array] = null, [Id!!Id] = Id, Code, [Name!!Name] = a.[Name]
	from acc.Accounts a
	where a.TenantId = @TenantId and Void = 0 and [Plan] is null and Parent is null and Void = 0
	order by a.Id;
end
go
------------------------------------------------
drop procedure if exists app.[Policy.Metadata];
drop procedure if exists app.[Policy.Update];
drop type if exists app.[Policy.TableType];
go
------------------------------------------------
create type app.[Policy.TableType]
as table (
	CheckRems nchar(1),
	AccPlanRems bigint
)
go
------------------------------------------------
create or alter procedure app.[Policy.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Policy app.[Policy.TableType];
	select [Policy!Policy!Metadata] = null, * from @Policy;
end
go
------------------------------------------------
create or alter procedure app.[Policy.Update]
@TenantId int = 1,
@UserId bigint,
@Policy app.[Policy.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	merge app.Settings as t
	using @Policy as s
	on t.TenantId = @TenantId and t.TenantId = @TenantId
	when matched then update set 
		t.CheckRems = s.CheckRems,
		t.AccPlanRems = s.AccPlanRems
	when not matched by target then insert
		(TenantId, CheckRems, AccPlanRems) values
		(@TenantId, CheckRems, AccPlanRems);

	exec app.[Policy.Load] @TenantId = @TenantId, @UserId = @UserId;
end
go

/* Tag */
------------------------------------------------
create or alter procedure cat.[Tag.For]
@TenantId int = 1,
@UserId bigint,
@For nvarchar(32),
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Tags!TTag!Array] = null,
		[Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color
	from cat.Tags t
	where t.TenantId = @TenantId and t.[For] = @For and t.Void = 0
	order by t.Id;
end
go
------------------------------------------------
create or alter procedure cat.[Tags.Load]
@TenantId int = 1,
@UserId bigint,
@For nvarchar(32),
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Tags!TTag!Array] = null,
		[Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color, t.[Memo], [For] = @For
	from cat.Tags t
	where t.TenantId = @TenantId and t.[For] = @For and t.Void = 0
	order by t.Id;

	select [Params!TParam!Object] = null, [For] = @For;
end
go
-------------------------------------------------
drop procedure if exists cat.[Tags.Metadata];
drop procedure if exists cat.[Tags.Update];
drop type if exists cat.[Tag.TableType];
go
-------------------------------------------------
create type cat.[Tag.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Memo] nvarchar(255),
	[For] nvarchar(32)
)
go

------------------------------------------------
create or alter procedure cat.[Tags.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Tag cat.[Tag.TableType];
	select [Tags!Tags!Metadata] = null, * from @Tag;
end
go
------------------------------------------------
create or alter procedure cat.[Tags.Update]
@TenantId int = 1,
@UserId bigint,
@Tags cat.[Tag.TableType] readonly,
@For nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	merge cat.Tags as t
	using @Tags as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Color] = s.[Color]
	when not matched by target then insert
		(TenantId,  [For], [Name], Color, Memo) values
		(@TenantId, @For, s.[Name], s.Color, s.Memo)
	when not matched by source and t.[For] = @For then update set
		t.Void = 1;
	exec cat.[Tags.Load] @TenantId = @TenantId, @UserId = @UserId, @For = @For;
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

	select [Company!TCompany!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], Memo,
		AutonumPrefix,
		[Logo.Id!TImage!Id] = c.Logo, [Logo.Token!TImage!Token] = lb.AccessToken
	from cat.Companies c
		left join app.Blobs lb on c.TenantId = lb.TenantId and c.Logo = lb.Id
	where c.TenantId = @TenantId and c.Id = @Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Company.Logo.Load]
@TenantId int = 1,
@UserId bigint,
@Key nvarchar(255),
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	set @TenantId = isnull(@TenantId, 1); -- required for image

	select Mime, [Stream], [Name], [Token] = AccessToken
	from app.Blobs where TenantId = @TenantId and Id = @Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Company.Logo.Update]
@TenantId int = 1,
@UserId bigint,
@Name nvarchar(255), 
@Mime nvarchar(255),
@Stream varbinary(max),
@BlobName nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	set @TenantId = isnull(@TenantId, 1); -- required for image

	declare @rtable table(id bigint, token uniqueidentifier);
	insert into app.Blobs(TenantId, [Name], Mime, [Stream], BlobName)
		output inserted.Id, inserted.AccessToken into @rtable(id, token)
	values (@TenantId, @Name, @Mime, @Stream, @BlobName);

	select Id = id, Token = token from @rtable;
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
	[Memo] nvarchar(255),
	AutonumPrefix nvarchar(8),
	Logo bigint
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
		t.[FullName] = s.[FullName],
		t.AutonumPrefix = s.AutonumPrefix,
		t.Logo = s.Logo
	when not matched by target then insert
		(TenantId, [Name], FullName, Memo, AutonumPrefix, Logo) values
		(@TenantId, s.[Name], s.FullName, s.Memo, s.AutonumPrefix, Logo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Company.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[Company.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Companies!TCompany!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo, c.FullName
	from cat.Companies c
	where TenantId = @TenantId and Void = 0 and
		([Name] like @fr or Memo like @fr or FullName like @fr)
	order by c.[Name];
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

	select [Warehouses!TWarehouse!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[RespPerson!TPerson!RefId] = RespPerson
	from cat.Warehouses w
	where w.TenantId = @TenantId;

	select [!TPerson!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Warehouses w 
		inner join cat.Agents a on a.TenantId = w.TenantId and w.RespPerson = a.Id
	where w.TenantId = @TenantId;
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

	select [Warehouse!TWarehouse!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[RespPerson!TPerson!RefId] = RespPerson
	from cat.Warehouses c
	where c.TenantId = @TenantId and c.Id = @Id;

	select [!TPerson!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Warehouses w 
		inner join cat.Agents a on a.TenantId = w.TenantId and w.RespPerson = a.Id
	where w.TenantId = @TenantId and w.Id = @Id;
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
	[Memo] nvarchar(255),
	RespPerson bigint
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
		t.[Memo] = s.[Memo],
		t.RespPerson = s.RespPerson
	when not matched by target then insert
		(TenantId, [Name], Memo, RespPerson) values
		(@TenantId, s.[Name], s.Memo, s.RespPerson)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Warehouse.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[Warehouse.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Warehouses!TWarehouse!Array] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name], w.Memo
	from cat.Warehouses w
	where TenantId = @TenantId and Void = 0 and
		([Name] like @fr or Memo like @fr)
	order by w.[Name];
end
go

/* Item */
drop type if exists cat.[view_Items.TableType];
go
-------------------------------------------------
create type cat.[view_Items.TableType]
as table (
	[Id!!Id] bigint,
	[Name!!Name] nvarchar(255),
	Article nvarchar(32),
	Barcode nvarchar(32),
	Memo nvarchar(255),
	[Unit.Id!TUnit!Id] bigint, 
	[Unit.Short!TUnit] nvarchar(8),
	[Role!TItemRole!RefId] bigint,
	[!TenantId] int, 
	[!IsStock] bit,
	Price float,
	Rem float,
	[!RowNo] int,
	[!!RowCount] int
);
go
-------------------------------------------------
create or alter view cat.view_Items
as
select [Id!!Id] = i.Id, 
	[Name!!Name] = i.[Name], i.Article, i.Barcode, i.Memo,
	[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
	[Role!TItemRole!RefId] = i.[Role],
	[!TenantId] = i.TenantId, [!IsStock] = ir.IsStock, Price = null, Rem = null, [!RowNo] = 0, [!!RowCount] = 0
from cat.Items i
	left join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
	left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
where i.Void = 0;
go
-------------------------------------------------
create or alter view cat.view_ItemRoles
as
select [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Color, ir.IsStock, ir.Kind,
	[CostItem.Id!TCostItem!Id] = ir.CostItem, [CostItem.Name!TCostItem!Name] = ci.[Name],
	[!TenantId] = ir.TenantId
from cat.ItemRoles ir
	left join cat.CostItems ci on ir.TenantId = ci.TenantId and ir.CostItem =ci.Id;
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Index]
@TenantId int = 1,
@UserId bigint,
@Group bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	if @Group is null
		select top(1) @Group = Id from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id = [Root] and Id <> 0;

	with T(Id, _order, [Name], HasChildren, Icon)
	as (
		select Id = -1, 0, [Name] = N'@[NoGrouping]', 0, Icon=N'package-outline'
		union all
		-- hack = negative!
		select Id = -@Group, 2, [Name] = N'@[WithoutGroup]', 0, Icon=N'ban' where @Group is not null
		union all
		select Id, 1, [Name],
			HasChildren= case when exists(
				select 1 from cat.ItemTree it where it.Void = 0 
				and it.Parent = t.Id and it.TenantId = @TenantId and t.TenantId = @TenantId
			) then 1 else 0 end,
			Icon = N'folder-outline'
		from cat.ItemTree t
			where t.TenantId = @TenantId and t.Void = 0 and t.Parent = @Group
	)
	select [Groups!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon,
		/*nested folders - lazy*/
		[Items!TGroup!Items] = null, 
		/* marker: subfolders exist */
		[HasSubItems!!HasChildren] = HasChildren,
		/*nested items (not folders!) */
		[Elements!TItem!LazyArray] = null
	from T
	order by _order, [Id];

	-- Elements definition
	select [!TItem!Tree] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], 
		i.Article, i.Barcode, i.Memo, [Role!TItemRole!RefId] = i.[Role],
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short, i.IsVariant,
		[Variants!TItem!Items] = null
	from cat.Items i
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	where 0 <> 0;

	select [!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Color, ir.IsStock
	from cat.ItemRoles ir 
	where 0 <> 0;

	-- filters
	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id <> Parent and Id <> 0;

	select [!$System!] = null,
		[!Hierarchies.Group!Filter] = @Group
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Expand]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Group bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Items!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[Items!TGroup!Items] = null,
		[HasSubItems!!HasChildren] = case when exists(select 1 from cat.ItemTree c where c.Void=0 and c.Parent=a.Id) then 1 else 0 end,
		Icon = N'folder-outline'
	from cat.ItemTree a where Parent = @Id and Void=0;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Elements]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null, -- GroupId
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
	set @fr = N'%' + @Fragment + N'%';

	declare @items table(rowno int identity(1, 1), id bigint, unit bigint, [role] bigint, rowcnt int);
	--@Id = ite.Parent or 
	insert into @items(id, unit, [role], rowcnt)
	select i.Id, i.Unit, i.[Role],
		count(*) over()
	from cat.Items i
		left join cat.ItemTreeElems ite on i.TenantId = ite.TenantId and i.Id = ite.Item
	where i.TenantId = @TenantId and i.Void = 0 and i.IsVariant = 0
		and (@Id = -1 or @Id = ite.Parent or (@Id < 0 and i.Id not in (
			select Item from cat.ItemTreeElems intbl where intbl.TenantId = @TenantId and intbl.[Root] = -@Id /*hack:negative*/
		)))
		and (@fr is null or [Name] like @fr or Memo like @fr or Article like @fr or Barcode like @fr)
	group by i.Id, i.Unit, i.[Name], i.Article, i.Barcode, i.Memo, i.[Role], i.Parent
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then i.[Name]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then i.[Name]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order 
				when N'id' then i.Id
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then i.Id
			end
		end desc,
		i.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Elements!TItem!Tree] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], 
		i.Article, i.Barcode, i.Memo, [Role!TItemRole!RefId] = i.[Role], i.IsVariant,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
		[Variants!TItem!Items] = null,
		[!!RowCount]  = t.rowcnt
	from @items t inner join cat.Items i on i.TenantId = @TenantId and i.Id = t.id
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	order by t.rowno;


	select [!TItem!Tree] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name],
		v.Article, v.Barcode, v.Memo, [Role!TItemRole!RefId] = t.[role],
		[Unit.Id!TUnit!Id] = v.Unit, [Unit.Short!TUnit] = u.Short, v.IsVariant,
		[!TItem.Variants!ParentId] = v.Parent
	from cat.Items v
		inner join @items t on v.TenantId = @TenantId and v.Parent = t.id
		left join cat.Units u on v.TenantId = u.TenantId and t.unit = u.Id
	where v.Void = 0
	order by v.Id;

	with R([role]) as (select [role] from @items group by [role])
	select [!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Color, ir.IsStock
	from cat.ItemRoles ir inner join R on ir.TenantId = @TenantId and ir.Id = R.[role];

	-- system data
	select [!$System!] = null,
		[!Elements!Offset] = @Offset, [!Elements!PageSize] = @PageSize, 
		[!Elements!SortOrder] = @Order, [!Elements!SortDir] = @Dir,
		[!Elements.Fragment!Filter] = @Fragment;
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
	where i.TenantId = @TenantId and i.Void = 0
		and (@fr is null or i.Name like @fr or i.FullName like @fr or i.Memo like @fr or i.Article like @fr or i.Barcode like @fr)
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
				when N'barcode' then i.Barcode
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
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Items!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode, i.Memo,
		[Role!TItemRole!RefId] = i.[Role], [Unit!TUnit!RefId] = i.Unit,
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
drop procedure if exists cat.[Item.Metadata];
drop procedure if exists cat.[Item.Update];
drop type if exists cat.[Item.TableType];
drop type if exists cat.[ItemTreeElem.TableType];
go
------------------------------------------------
create type cat.[Item.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	Article nvarchar(32),
	Barcode nvarchar(32),
	FullName nvarchar(255),
	[Memo] nvarchar(255),
	[Role] bigint,
	Unit bigint,
	Vendor bigint,
	Brand bigint,
	Country nchar(3)
);
go
-------------------------------------------------
create type cat.[ItemTreeElem.TableType]
as table(
	[Group] bigint, -- Parent
	ParentId bigint -- Root
);
go
------------------------------------------------
create or alter procedure cat.[Item.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Item!TItem!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.FullName, i.Article, i.Barcode, i.Memo,
		[Role!TItemRole!RefId] = i.[Role], [Unit!TUnit!RefId] = i.Unit, 
		[Brand!TBrand!RefId] = i.Brand, [Vendor!TVendor!RefId] = i.Vendor,
		[Country!TCountry!RefId] = i.Country,
		[Variants!TVariant!Array] = null
	from cat.Items i 
	where i.TenantId = @TenantId and i.Id=@Id and i.Void = 0;

	select [!TVariant!Array] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Article, v.Barcode, v.Memo,
		v.IsVariant, [Role!TItemRole!RefId] = v.[Role], [Unit!TUnit!RefId] = v.Unit, 
		[!TItem.Variants!ParentId] = v.Parent
	from cat.Items v 
	where v.TenantId = @TenantId and v.Parent = @Id and v.Void = 0;


	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[Elements!THieElem!Array] = null
	from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id = [Root] and Id <> 0;

	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.Short
	from cat.Units u
		inner join cat.Items i on u.TenantId = i.TenantId and u.Id = i.Unit
	where i.TenantId = @TenantId and i.Id = @Id;

	select [!TBrand!Map] = null, [Id!!Id] = b.Id, [Name!!Name] = b.[Name]
	from cat.Brands b
		inner join cat.Items i on b.TenantId = i.TenantId and b.Id = i.Brand
	where i.TenantId = @TenantId and i.Id = @Id;

	select [!TVendor!Map] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name]
	from cat.Vendors v
		inner join cat.Items i on v.TenantId = i.TenantId and v.Id = i.Vendor
	where i.TenantId = @TenantId and i.Id = @Id;

	select [!TCountry!Map] = null, [Id!!Id] = c.Code, [Name!!Name] = c.[Name]
	from cat.Countries c
		inner join cat.Items i on c.TenantId = i.TenantId and c.Code = i.Country
	where i.TenantId = @TenantId and i.Id = @Id;

	select [ItemRoles!TItemRole!Array] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Color, ir.IsStock,
		[CostItem.Id!TCostItem!Id] = ir.CostItem, [CostItem.Name!TCostItem!Name] = ci.[Name],
		[Accounts!TItemRoleAcc!Array] = null
	from cat.ItemRoles ir 
		left join cat.CostItems ci on ir.TenantId = ci.TenantId and ir.CostItem =ci.Id
	where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Item';
	
	select [!THieElem!Array] = null, [!THie.Elements!ParentId] = iti.[Root],
		[Group] = iti.Parent,
		[Path] = cat.fn_GetItemBreadcrumbs(@TenantId, iti.Parent, null)
	from cat.ItemTreeElems iti 
	where TenantId = @TenantId  and iti.Item = @Id;

	-- TItemRoleAcc
	select [!TItemRoleAcc!LazyArray] = null, [Plan] = p.Code, Kind = ak.[Name], Account = a.Code,
		[!TItemRole.Accounts!ParentId] = ira.[Role], PlanName = p.[Name], AccountName = a.[Name]
	from cat.ItemRoleAccounts ira
		inner join cat.ItemRoles ir on ira.TenantId = ir.TenantId and ira.[Role] = ir.Id
		inner join acc.Accounts p on ira.TenantId = p.TenantId and ira.[Plan] = p.Id
		inner join acc.AccKinds ak on ira.TenantId = ak.TenantId and ira.AccKind = ak.Id
		inner join acc.Accounts a on ira.TenantId = a.TenantId and ira.Account = a.Id
	where ira.TenantId = @TenantId and ir.Kind = N'Item'
	order by ira.Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Item cat.[Item.TableType];
	declare @Groups cat.[ItemTreeElem.TableType];
	select [Item!Item!Metadata] = null, * from @Item;
	select [Groups!Hierarchies.Elements!Metadata] = null, * from @Groups;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Update]
@TenantId int = 1,
@UserId bigint,
@Item cat.[Item.TableType] readonly,
@Groups cat.[ItemTreeElem.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Groups for xml auto);
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
			t.Barcode = s.Barcode,
			t.Memo = s.Memo,
			t.[Role] = s.[Role],
			t.Unit = s.Unit,
			t.Brand = s.Brand,
			t.Vendor = s.Vendor,
			t.Country = s.Country
	when not matched by target then 
		insert (TenantId, [Name], FullName, [Article], Barcode, Memo, [Role], Unit, Brand, Vendor, Country)
		values (@TenantId, s.[Name], s.FullName, s.Article, s.Barcode, s.Memo, s.[Role], s.Unit, s.Brand, s.Vendor, s.Country)
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	merge cat.ItemTreeElems as t
	using @Groups as s
	on t.TenantId = @TenantId and t.[Root] = s.ParentId and t.[Parent] = s.[Group] and t.Item = @RetId
	when not matched by target then insert
		(TenantId, [Root], [Parent], Item) values
		(@TenantId, s.ParentId, s.[Group], @RetId)
	when not matched by source and t.TenantId = @TenantId and t.Item = @RetId then delete;

	-- update variants
	with TV as (
		select v.Id, p.[Role], p.Unit, p.Vendor, p.Brand, p.Country
		from cat.Items v inner join cat.Items p on v.TenantId = p.TenantId and v.Parent = p.Id
		where p.TenantId = @TenantId and p.Id = @RetId
	)
	update cat.Items set Unit = TV.Unit, [Role] = TV.[Role], [Vendor] = TV.Vendor, Brand = TV.Brand, Country = TV.Country
	from TV inner join cat.Items v on v.TenantId = @TenantId and v.Id = TV.Id;

	commit tran;

	exec cat.[Item.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @RetId;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Folder.GetPath]
@TenantId int = 1,
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
/*
create or alter procedure cat.[Item.Item.FindIndex]
@TenantId int = 1,
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
	select [Result!TResult!Object] = null, T.Id, RowNo = T.RowNumber - 1 / *row_number is 1-based* /
	from T
	where T.Id = @Id;
end
*/
go
------------------------------------------------
create or alter procedure cat.[Item.Folder.Delete]
@TenantId int = 1,
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
	/*
	delete from cat.ItemTreeItems where
		TenantId = @TenantId and Item = @Id;
	*/
	commit tran;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Find.ArticleOrBarcode]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255) = null,
@PriceKind bigint = null,
@Date date = null,
@Wh bigint = null,
@Mode nchar(1) = N'A',
@Stock bit = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	declare  @item cat.[view_Items.TableType];
	insert into @item
	select top(1) *
	from cat.view_Items i
	where i.[!TenantId] = @TenantId and (@Stock is null or i.[!IsStock] = @Stock) and
		((@Mode = N'A' and i.Article = @Text) or (@Mode = 'B' and i.Barcode = @Text));

	if @PriceKind is not null
		update @item set Price = doc.fn_PriceGet(@TenantId, [Id!!Id], @PriceKind, @Date);
	if @Wh is not null
		update @item set Rem = doc.fn_getOneItemRem(@TenantId, [Id!!Id], [Role!TItemRole!RefId], @Date, @Wh);

	select [Item!TItem!Object] = null, *
	from @item;

	select [!TItemRole!Map] = null, * 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId and vir.[Id!!Id] in (select [Role!TItemRole!RefId] from @item);
end
go
------------------------------------------------
create or alter procedure cat.[Item.Find.Barcode]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare  @item cat.[view_Items.TableType];
	insert into @item
	select top(1) *
	from cat.view_Items i
	where i.[!TenantId] = @TenantId and i.Barcode = @Text;

	select [Item!TItem!Object] = null, *
	from @item;

	select [!TItemRole!Map] = null, * 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId and vir.[Id!!Id] in (select [Role!TItemRole!RefId] from @item);
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Rems.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Item!TItem!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Items where TenantId = @TenantId and Id = @Id;

	select [Rems!TRem!Array] = null, WhId =  Id, [WhName] = w.[Name]
	from cat.Warehouses w where TenantId = @TenantId
	order by Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Elements.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	if exists(select 1 from doc.DocDetails where TenantId = @TenantId and Item = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	begin tran;
	delete from cat.ItemTreeElems where TenantId = @Id and Item = @Id;
	update cat.Items set Void = 1 where TenantId = @TenantId and Id=@Id;
	commit tran;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	exec cat.[Item.Group.Elements.Delete] @TenantId = @TenantId, @UserId = @UserId, @Id = @Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.FillList]
@TenantId int = 1,
@GroupId bigint = -1, -- GroupId
@IsStock nchar(1) = N'A',
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	declare @stock bit;

	set @stock = case @IsStock when N'T' then 1 when N'V' then 0 else null end;
	set @Dir = lower(@Dir);
	set @Order = lower(@Order);

	set @fr = N'%' + @Fragment + N'%';

	declare @items table(rowno int identity(1, 1), id bigint, unit bigint, [role] bigint, rowcnt int);
	--@Id = ite.Parent or 
	insert into @items(id, unit, [role], rowcnt)
	select i.Id, i.Unit, i.[Role],
		count(*) over()
	from cat.Items i
		left join cat.ItemTreeElems ite on i.TenantId = ite.TenantId and i.Id = ite.Item
		left join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
	where i.TenantId = @TenantId and i.Void = 0
		and (@GroupId = -1 or @GroupId = ite.Parent or (@GroupId < 0 and i.Id not in (
			select Item from cat.ItemTreeElems intbl where intbl.TenantId = @TenantId and intbl.[Root] = -@GroupId /*hack:negative*/
		)))
		and (@stock is null or isnull(ir.IsStock, 0) = @stock)
		and (@fr is null or i.[Name] like @fr or i.Memo like @fr or Article like @fr or ir.[Name] like @fr or Barcode like @fr)
	group by i.Id, i.Unit, i.[Name], i.Article, i.Barcode, i.Memo, i.[Role], ir.[Name]
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then i.[Name]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
				when N'role' then ir.[Name]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then i.[Name]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
				when N'role' then ir.[Name]
			end
		end desc,
		i.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select id, rowno, unit, [role], rowcnt from @items;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Browse.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@IsStock nchar(1) = null,
@Wh bigint = null,
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @source table(rowno int, id bigint, unit bigint, [role] bigint, rowcnt int);

	insert into @source(id, rowno, unit, [role], rowcnt)
		exec cat.[Item.FillList] @TenantId = @TenantId, @PageSize = @PageSize, @Dir = @Dir, @Order = @Order, @Offset=@Offset,
			@IsStock = @IsStock, @Fragment = @Fragment;

	select [Items!TItem!Array] = null, 
			[Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], [!!RowCount] = s.rowcnt
	from cat.view_Items v
	inner join @source s on v.[Id!!Id] = s.id
	where v.[!TenantId] = @TenantId
	order by v.[!RowNo], v.[Id!!Id];

	-- all
	select [!TItemRole!Map] = null, vir.* 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId;

	-- system data
	select [!$System!] = null,
		[!Items!Offset] = @Offset, [!Items!PageSize] = @PageSize, 
		[!Items!SortOrder] = @Order, [!Items!SortDir] = @Dir,
		[!Items.Fragment!Filter] = @Fragment;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Browse.Price.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@IsStock nchar(1) = null,
@PriceKind bigint = null,
@Date datetime = null,
@CheckRems bit = 0,
@Wh bigint = null,
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	declare @source table(rowno int, id bigint, unit bigint, [role] bigint, rowcnt int);

	insert into @source(id, rowno, unit, [role], rowcnt)
		exec cat.[Item.FillList] @TenantId = @TenantId, @PageSize = @PageSize, @Dir = @Dir, @Order = @Order, @Offset=@Offset,
			@IsStock = @IsStock, @Fragment = @Fragment;

	declare @items cat.[view_Items.TableType];

	if @CheckRems = 1
	begin
		declare @itemstable a2sys.[Id.TableType];
		insert into @itemstable(Id) select id from @source;

		insert into @items([Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], Price, Rem, [!RowNo], [!!RowCount])
		select v.[Id!!Id], v.[Name!!Name], v.Article, v.Barcode, v.Memo, v.[Unit.Id!TUnit!Id], v.[Unit.Short!TUnit],
			isnull(t.[Role], v.[Role!TItemRole!RefId]), @TenantId, v.[!IsStock], v.Price, t.Rem, s.rowno, s.rowcnt
		from cat.view_Items v
			inner join @source s on v.[!TenantId] = @TenantId and s.id = v.[Id!!Id]
			left join doc.fn_getItemsRems(@CheckRems, @TenantId, @itemstable, @Date, @Wh) t
			on t.Item = v.[Id!!Id]
		where 
			v.[!TenantId] = @TenantId
	end
	else
	begin
		insert into @items ([Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], Price, Rem, [!RowNo], [!!RowCount])
		select v.[Id!!Id], v.[Name!!Name], v.Article, v.Barcode, v.Memo, v.[Unit.Id!TUnit!Id], v.[Unit.Short!TUnit],
			v.[Role!TItemRole!RefId], @TenantId, v.[!IsStock], 0, 0, [!RowNo] = s.rowno, [!!RowCount] = s.rowcnt
		from cat.view_Items v
			inner join @source s on v.[Id!!Id] = s.id
		where v.[!TenantId] = @TenantId
	end;

	-- update prices
	if @PriceKind is not null
	begin
		with TP as (
			select p.Item, [Date] = max(p.[Date])
			from doc.Prices p inner join @items t on p.TenantId = @TenantId and p.Item = t.[Id!!Id] and 
				p.[Date] <= @Date and p.PriceKind = @PriceKind
			group by p.Item, p.PriceKind
		),
		TX as (
			select p.Price, p.Item
			from doc.Prices p inner join TP on p.TenantId = @TenantId and p.Item = TP.Item 
				and p.PriceKind = @PriceKind and TP.[Date] = p.[Date]
		)
		update @items set Price = TX.Price 
		from @items t inner join TX on t.[Id!!Id] = TX.Item;
	end

	select [Items!TItem!Array] = null, v.*
	from @items v
	order by v.[!RowNo], v.[Id!!Id];

	-- all roles
	select [!TItemRole!Map] = null, vir.* 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId;

	select [PriceKind!TPriceKind!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Date] = @Date
	from cat.PriceKinds where TenantId = @TenantId and Id = @PriceKind;

	select [Params!TParam!Object] = null, CheckRems = @CheckRems, [Date] = @Date,
		[Warehouse.Id!TWarehouse!Id] = @Wh, [Warehouse.Name!TWarehouse!Name] = cat.fn_GetWarehouseName(@TenantId, @Wh);

	-- system data
	select [!$System!] = null,
		[!Items!Offset] = @Offset, [!Items!PageSize] = @PageSize, 
		[!Items!SortOrder] = @Order, [!Items!SortDir] = @Dir,
		[!Items.Fragment!Filter] = @Fragment;
end
go

-------------------------------------------------
create or alter procedure cat.[Item.Fetch.Price]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@IsStock nchar(1) = null,
@PriceKind bigint = null,
@Date datetime = null,
@CheckRems bit = 0,
@Wh bigint = null,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	declare @source table(rowno int, id bigint, unit bigint, [role] bigint, rowcnt int);

	insert into @source(id, rowno, unit, [role], rowcnt)
		exec cat.[Item.FillList] @TenantId = @TenantId, @PageSize = 100, @Dir = N'name', @Order = N'asc', @Offset=0,
			@IsStock = @IsStock, @Fragment = @Text;

	declare @items cat.[view_Items.TableType];

	if @CheckRems = 1
	begin
		declare @itemstable a2sys.[Id.TableType];
		insert into @itemstable(Id) select id from @source;

		insert into @items([Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], Price, Rem, [!RowNo], [!!RowCount])
		select v.[Id!!Id], v.[Name!!Name], v.Article, v.Barcode, v.Memo, v.[Unit.Id!TUnit!Id], v.[Unit.Short!TUnit],
			isnull(t.[Role], v.[Role!TItemRole!RefId]), @TenantId, v.[!IsStock], v.Price, t.Rem, s.rowno, s.rowcnt
		from cat.view_Items v
			inner join @source s on v.[!TenantId] = @TenantId and s.id = v.[Id!!Id]
			left join doc.fn_getItemsRems(@CheckRems, @TenantId, @itemstable, @Date, @Wh) t
			on t.Item = v.[Id!!Id]
		where 
			v.[!TenantId] = @TenantId;
	end
	else
	begin
		insert into @items ([Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], Price, Rem, [!RowNo], [!!RowCount])
		select v.[Id!!Id], v.[Name!!Name], v.Article, v.Barcode, v.Memo, v.[Unit.Id!TUnit!Id], v.[Unit.Short!TUnit],
			v.[Role!TItemRole!RefId], @TenantId, v.[!IsStock], 0, 0, [!RowNo] = s.rowno, [!!RowCount] = s.rowcnt
		from cat.view_Items v
			inner join @source s on v.[Id!!Id] = s.id
		where v.[!TenantId] = @TenantId
	end;

	-- update prices
	if @PriceKind is not null
	begin
		with TP as (
			select p.Item, [Date] = max(p.[Date])
			from doc.Prices p inner join @items t on p.TenantId = @TenantId and p.Item = t.[Id!!Id] and 
				p.[Date] <= @Date and p.PriceKind = @PriceKind
			group by p.Item, p.PriceKind
		),
		TX as (
			select p.Price, p.Item
			from doc.Prices p inner join TP on p.TenantId = @TenantId and p.Item = TP.Item 
				and p.PriceKind = @PriceKind and TP.[Date] = p.[Date]
		)
		update @items set Price = TX.Price 
		from @items t inner join TX on t.[Id!!Id] = TX.Item;
	end

	select [Items!TItem!Array] = null, v.*
	from @items v
	order by v.[!RowNo], v.[Id!!Id];

	-- all roles
	select [!TItemRole!Map] = null, vir.* 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId;
end
go

------------------------------------------------
drop procedure if exists cat.[Item.Variant.Create.Metadata];
drop procedure if exists cat.[Item.Variant.Create.Update];
drop type if exists cat.[Item.Variant.Item.TableType];
drop type if exists cat.[Item.Variant.Variant.TableType];
go
------------------------------------------------
create type cat.[Item.Variant.Item.TableType] as table
(
	[GUID] uniqueidentifier,
	Id bigint
)
go
------------------------------------------------
create type cat.[Item.Variant.Variant.TableType] as table
(
	Id1 bigint,
	Id2 bigint,
	Id3 bigint,
	[Name] nvarchar(255),
	[Article] nvarchar(32),
	[Barcode] nvarchar(32)
)
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Create.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as 
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Item!TItem!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode,
		[Option1!TOption!RefId] = cast(null as bigint),
		[Option2!TOption!RefId] = cast(null as bigint),
		[Option3!TOption!RefId] = cast(null as bigint),
		[Variants!TVariant!Array] = null,
		[Result!TResult!Array] = null
	from cat.Items i
	where TenantId = @TenantId and Id = @Id;

	select [Options!TOption!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[Values!TOptionValue!Array] = null
	from cat.ItemOptions 
	where TenantId = @TenantId
	order by Id;

	select [!TOptionValue!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[!TOption.Values!ParentId] = [Option], Checked = cast(1 as bit)
	from cat.ItemOptionValues
	where TenantId = @TenantId and Void = 0;

	select [!TVariant!Array] = null, 
		[Id1] = cast(null as bigint), [Name1] = cast(null as nvarchar(255)),
		[Id2] = cast(null as bigint), [Name2] = cast(null as nvarchar(255)),
		[Id3] = cast(null as bigint), [Name3] = cast(null as nvarchar(255)),
		Article = cast(null as nvarchar(32)), Barcode = cast(null as nvarchar(32)),
		[!TItem.Variants!ParentId] = @Id
	where 0 <> 0;

	select [!TResult!Array] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Article, v.Barcode, v.Memo,
		v.IsVariant, [!TItem.Result!ParentId] = @Id
	from cat.Items v 
	where 0 <> 0;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Create.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Item cat.[Item.Variant.Item.TableType];
	declare @Variants cat.[Item.Variant.Variant.TableType];

	select [Item!Item!Metadata] = null, * from @Item;
	select [Variants!Item.Variants!Metadata] = null, * from @Variants;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Create.Update]
@TenantId int = 1,
@UserId bigint,
@Item cat.[Item.Variant.Item.TableType] readonly,
@Variants cat.[Item.Variant.Variant.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @itemid bigint;
	declare @itemname nvarchar(255);
	declare @role bigint;
	declare @unit bigint;

	select @itemid = i.Id, @itemname = i.[Name], @role = i.[Role], @unit = i.Unit
	from @Item t inner join cat.Items i on i.TenantId = @TenantId and i.Id = t.Id;

	declare @vars table(id bigint, [name] nvarchar(255), [article] nvarchar(32), barcode nvarchar(32));

	begin tran;
	-- insert into @vars with source columns
	merge cat.ItemVariants as t
	using @Variants as s
	on (0 <> 0)
	when not matched then insert
		(TenantId, Option1, Option2, Option3, [Name]) values
		(@TenantId, nullif(Id1, 0), nullif(Id2, 0), nullif(Id3, 0), [Name])
	output inserted.Id, inserted.[Name], s.Article, s.Barcode into @vars(id, [name], article, barcode);

	insert into cat.Items(TenantId, Parent, [Role], Unit, [Name], Variant, Article, Barcode)
	select @TenantId, @itemid, @role, @unit, @itemname + N' [' + v.[name] + N']', v.id, v.article, v.barcode
	from @vars v
	commit tran;

	select [Item!TItem!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode,
		[Result!TResult!Array] = null
	from cat.Items i
	where TenantId = @TenantId and Id = @itemid;

	select [!TVariant!Array] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Article, v.Barcode, v.Memo,
		[Role.Id!TItemRole!Id] = v.[Role], [Role.Name!TItemRole!Name] = ir.[Name], [Role.Color!TItemRole!] = ir.Color,
		v.IsVariant, [!TItem.Result!ParentId] = @itemid
	from cat.Items v 
		left join cat.ItemRoles ir on v.TenantId = ir.TenantId and v.[Role] = ir.Id
	where v.TenantId = @TenantId and v.Parent = @itemid and v.Void = 0 and v.IsVariant = 1;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @vart bigint;
	select @vart = Variant from cat.Items where TenantId = @TenantId and Id = @Id;

	select [Variant!TVariant!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name],
		i.Barcode, i.Article, i.Memo, i.IsVariant,
		[Option1!TOption!RefId] = iv.Option1, [Option2!TOption!RefId] = iv.Option2, [Option3!TOption!RefId] = iv.Option3,
		[ParentName] = p.[Name],
		[Role.Id!TItemRole!Id] = i.[Role], [Role.Name!TItemRole!Name] = ir.[Name], [Role.Color!TItemRole!] = ir.Color
	from cat.Items i
		inner join cat.Items p on i.TenantId = p.TenantId and i.Parent = p.Id
		left join cat.ItemVariants iv on i.TenantId = iv.TenantId and i.Variant = iv.Id
		left join cat.ItemOptionValues ov1 on ov1.TenantId = iv.TenantId and iv.Option1 = ov1.Id
		left join cat.ItemRoles ir on ir.TenantId = i.TenantId and i.[Role] = ir.Id
	where i.TenantId = @TenantId and i.Id = @Id;

	select [!TOption!Map] = null, [Id!!Id] = ov.Id, [Name!!Name] = o.[Name], [Value] = ov.[Name]
	from cat.ItemOptionValues ov 
		inner join cat.ItemVariants iv on ov.TenantId = iv.TenantId and ov.Id in (iv.Option1, iv.Option2, iv.Option3)
		inner join cat.ItemOptions o on iv.TenantId = o.TenantId and o.Id = ov.[Option]
	where iv.Id = @vart
end
go
------------------------------------------------
drop procedure if exists cat.[Item.Variant.Metadata];
drop procedure if exists cat.[Item.Variant.Update];
drop type if exists cat.[Item.Variant.TableType];
go
------------------------------------------------
create type cat.[Item.Variant.TableType] as table
(
	[Id] bigint,
	[Name] nvarchar(255),
	Article nvarchar(32),
	Barcode nvarchar(32),
	Memo nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Variant cat.[Item.Variant.TableType];
	select [Variant!Variant!Metadata] = null, * from @Variant;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Update]
@TenantId int = 1,
@UserId bigint,
@Variant cat.[Item.Variant.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	merge cat.Items as t
	using @Variant as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.Article = s.Article,
		t.Barcode = s.Barcode,
		t.Memo = s.Memo;

	-- simple variant for update UI
	select [Variant!TVariant!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name],
		i.Barcode, i.Article, i.Memo, i.IsVariant,
		[Role.Id!TItemRole!Id] = i.[Role], [Role.Name!TItemRole!Name] = ir.[Name], [Role.Color!TItemRole!] = ir.Color
	from cat.Items i inner join @Variant v on i.TenantId = @TenantId and i.Id = v.Id
	inner join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
end
go









/* ITEM GROUPING */
------------------------------------------------
create or alter procedure cat.[GroupItem.Index]
@TenantId int = 1,
@UserId bigint,
@Hierarchy bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- default filter
	--if @Hierarchy is null
		--select top(1) @Hierarchy = Id from cat.ItemTree where @TenantId = @TenantId and Void = 0 and Parent = 0 and Id <> 0;

	with T(Id, [Name], Icon, HasChildren)
	as (
		select Id, [Name], Icon = N'folders-outline',
			HasChildren= case when exists(
				select 1 from cat.ItemTree it where it.Void = 0 and it.Parent = t.Id 
					and it.TenantId = @TenantId and t.TenantId = @TenantId
			) then 1 else 0 end
		from cat.ItemTree t
			where t.TenantId = @TenantId and t.Void = 0 and t.Id <> 0 and t.Parent = 0 and t.Id = t.[Root]
	)
	select [Groups!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon, [IsRoot] = cast(1 as bit),
		/*nested folders - lazy*/
		[Items!TGroup!Items] = null, 
		/* marker: subfolders exist */
		[HasItems!!HasChildren] = HasChildren
	from T
	order by [Id];

	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where 
	TenantId = @TenantId and Void = 0 and Id <> 0 and [Root] = Id and [Parent] = 0;

	select [!$System!] = null,
		[!Groups.Hierarchy!Filter] = @Hierarchy;
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Expand]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Hierarchy bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Items!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon = N'folder-outline',
		[Items!TGroup!Items] = null,
		[HasItems!!HasChildren] = case when exists(select 1 from cat.ItemTree c where c.Void=0 and c.Parent=a.Id) then 1 else 0 end
	from cat.ItemTree a where Parent = @Id and Void=0;
end
go
------------------------------------------------
create or alter procedure cat.[GroupItem.Browse.Index]
@TenantId int = 1,
@UserId bigint,
@Hierarchy bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with T(Id, Parent, [Level])
	as (
		select it.Id, cast(null as bigint), 0
		from cat.ItemTree it
			where it.TenantId = @TenantId and it.Void = 0 and it.Parent = @Hierarchy and it.[Root] <> it.Id
		union all 
		select it.Id, it.Parent, T.[Level] + 1
		from T inner join cat.ItemTree it on it.TenantId = @TenantId and T.Id = it.Parent
		where it.TenantId = @TenantId and it.Void = 0
	)
	select [Groups!TGroup!Tree] = null, [Id!!Id] = it.Id, [Name!!Name] = it.[Name], Icon = N'folder-outline',
		[Group!TGroup.Items!ParentId] = T.Parent,
		[Items!TGroup!Items] = null
	from T
		inner join cat.ItemTree it on it.TenantId = @TenantId and it.Id = T.Id
	order by T.[Level], it.[Id];
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Parent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	if @Parent is null
		select @Parent = [Parent] from cat.ItemTree where @TenantId = @TenantId and Id=@Id;

	select [Group!TGroup!Object] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name],
		[ParentGroup.Id!TParentGroup!Id] = t.Parent, [ParentGroup.Name!TParentGroup!Name] = p.[Name]
	from cat.ItemTree t
		inner join cat.ItemTree p on t.TenantId = p.TenantId and t.Parent = p.Id
	where t.TenantId=@TenantId and t.Id = @Id and t.Void = 0;

	select [ParentGroup!TParentGroup!Object] = null,  [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree 
	where Id=@Parent and TenantId = @TenantId;
end
go
------------------------------------------------
create or alter procedure cat.[HierarchyItem.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Group!TGroup!Object] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name]
	from cat.ItemTree t
	where t.TenantId=@TenantId and t.Id = @Id and t.Void = 0;
end
go
------------------------------------------------
drop procedure if exists cat.[GroupItem.Metadata];
drop procedure if exists cat.[GroupItem.Update];
drop procedure if exists cat.[HierarchyItem.Metadata];
drop procedure if exists cat.[HierarchyItem.Update];
drop type if exists cat.[GroupItem.TableType];
go
------------------------------------------------
create type cat.[GroupItem.TableType]
as table(
	Id bigint null,
	ParentGroup bigint,
	[Name] nvarchar(255)
)
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Group cat.[GroupItem.TableType];
	select [Group!Group!Metadata] = null, * from @Group;
end
go
-------------------------------------------------
create or alter procedure cat.[HierarchyItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Group cat.[GroupItem.TableType];
	select [Group!Group!Metadata] = null, * from @Group;
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Update]
@TenantId int = 1,
@UserId bigint,
@Group cat.[GroupItem.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output table(op sysname, id bigint);
	declare @Root bigint;
	select top(1) @Root = [Root] from cat.ItemTree it
	inner join @Group g on it.TenantId = @TenantId and it.Id = g.ParentGroup;

	merge cat.ItemTree as t
	using @Group as s
	on (t.Id = s.Id and t.TenantId = @TenantId)
	when matched then
		update set 
			t.[Name] = s.[Name]
	when not matched by target then 
		insert (TenantId, [Root], Parent, [Name])
		values (@TenantId, @Root, s.ParentGroup, s.[Name])
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	select [Group!TGroup!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon=N'folder-outline',
		ParentFolder = Parent
	from cat.ItemTree
	where  TenantId = @TenantId and Id=@RetId;
end
go
-------------------------------------------------
create or alter procedure cat.[HierarchyItem.Update]
@TenantId int = 1,
@UserId bigint,
@Group cat.[GroupItem.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output table(op sysname, id bigint);

	begin tran;
	merge cat.ItemTree as t
	using @Group as s
	on (t.Id = s.Id and t.TenantId = @TenantId)
	when matched then
		update set 
			t.[Name] = s.[Name]
	when not matched by target then 
		insert (TenantId, [Root], Parent, [Name])
		values (@TenantId, 0, 0, s.[Name])
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	update cat.ItemTree set [Root] = @RetId where TenantId=@TenantId and Id=@RetId and Parent = 0;
	commit tran;

	select [Group!TGroup!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], IsRoot = 1,
		Icon=N'folders-outline'
	from cat.ItemTree
	where  TenantId = @TenantId and Id=@RetId;
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Hierarchies.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Groups!TGroup!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where TenantId = @TenantId and Id <> 0 and Parent = 0 and Id = [Root]
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	begin tran;

	delete from cat.ItemTreeElems where TenantId = @TenantId and Parent = @Id;
	delete from cat.ItemTree where TenantId = @TenantId and Id = @Id;

	commit tran;
end
go
/* ITEM OPTIONS */
------------------------------------------------
create or alter procedure cat.[ItemOption.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Options!TOption!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Memo],
		[Items!TOptionValue!Array] = null
	from cat.ItemOptions 
	where TenantId = @TenantId and Void = 0;

	select [!TOptionValue!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[!TOption.Items!ParentId] = [Option]
	from cat.ItemOptionValues
	where TenantId = @TenantId and Void = 0;
end
go
-------------------------------------------------
create or alter procedure cat.[ItemOption.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Option!TOption!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Memo],
		[Items!TOptionValue!Array] = null
	from cat.ItemOptions 
	where TenantId = @TenantId and Id = @Id;

	select [!TOptionValue!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[!TOption.Items!ParentId] = [Option]
	from cat.ItemOptionValues
	where TenantId = @TenantId and [Option] = @Id and Void = 0
end
go
------------------------------------------------
drop procedure if exists cat.[ItemOption.Metadata];
drop procedure if exists cat.[ItemOption.Update];
drop type if exists cat.[ItemOption.TableType];
drop type if exists cat.[ItemOptionValue.TableType];
go
------------------------------------------------
create type cat.[ItemOption.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
);
go
-------------------------------------------------
create type cat.[ItemOptionValue.TableType]
as table (
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
);
go
-------------------------------------------------
create or alter procedure cat.[ItemOption.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Option cat.[ItemOption.TableType];
	declare @Values cat.[ItemOptionValue.TableType];

	select [Option!Option!Metadata] = null, * from @Option;
	select [Values!Option.Items!Metadata] = null, * from @Values;
end
go
-------------------------------------------------
create or alter procedure cat.[ItemOption.Update]
@TenantId int = 1,
@UserId bigint,
@Option [ItemOption.TableType] readonly,
@Values cat.[ItemOptionValue.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output table(op sysname, id bigint);

	merge cat.ItemOptions as t
	using @Option as s
	on (t.Id = s.Id and t.TenantId = @TenantId)
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Memo] = s.Memo
	when not matched by target then 
		insert (TenantId, [Name], Memo)
		values (@TenantId, s.[Name], s.Memo)
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	with TV as (
		select * from cat.ItemOptionValues where TenantId = @TenantId and [Option] = @RetId and Void = 0
	)
	merge TV as t
	using @Values as s
	on (t.Id = s.Id)
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Memo] = s.Memo,
		t.Void = 0
	when not matched by target then 
		insert (TenantId, [Option], [Name], Memo)
		values (@TenantId, @RetId, s.[Name], s.Memo)
	when not matched by source then update set
		t.Void = 1;

	exec cat.[ItemOption.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @RetId;
end
go
-------------------------------------------------
create or alter procedure cat.[ItemOption.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	begin tran;
	update cat.ItemOptions set Void = 1 where TenantId = @TenantId and Id = @Id;
	commit tran;
end
go
/* Account */
-------------------------------------------------
create or alter procedure acc.[Account.Plan.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	
	declare @fr nvarchar(255) = N'%' + @Text + N'%';

	select [Accounts!TAccount!Array] = null, [Id!!Id] = a.Id, a.Code, a.[Name], a.[Plan], a.IsFolder
	from acc.Accounts a where a.[Plan] is null and a.Parent is null and Void = 0 and 
		(a.Code like @fr or a.[Name] like @fr);
end
go

-------------------------------------------------
create or alter procedure acc.[Account.Fetch]
@TenantId int = 1,
@UserId bigint,
@Plan bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	
	declare @fr nvarchar(255) = N'%' + @Text + N'%';

	select [Accounts!TAccount!Array] = null, [Id!!Id] = a.Id, a.Code, a.[Name], a.[Plan], a.IsFolder
	from acc.Accounts a where 
		a.[Plan] = @Plan and Void = 0 and IsFolder = 0 and (a.Code like @fr or a.[Name] like @fr);
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
		FullName, [Memo], [Tags!TTag!Array] = null
	from cat.Agents a
	where TenantId = @TenantId and [Partner] = 1

	select [!TTag!Array] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color,
		[!TAgent.Tags!ParentId] = ta.Agent
	from cat.TagsAgent ta inner join cat.Tags t on ta.TenantId = t.TenantId and ta.Tag = t.Id
	where ta.TenantId = @TenantId and t.TenantId = @TenantId
	order by t.Id;
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
		FullName, [Memo], IsSupplier, IsCustomer,
		[Contacts!TContact!Array] = null,
		[Tags!TTag!Array] = null
	from cat.Agents a
	where TenantId = @TenantId and Id = @Id;

	select [!TContact!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Birthday, c.Gender,
		c.Position,
		[!TAgent.Contacts!ParentId] = ac.Agent
	from cat.Contacts c
		inner join cat.AgentContacts ac on c.TenantId = ac.TenantId and c.Id = ac.Contact
	where ac.TenantId = @TenantId and ac.Agent = @Id;

	select [!TTag!Array] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color,
		[!TAgent.Tags!ParentId] = ta.Agent
	from cat.TagsAgent ta 
		inner join cat.Tags t on ta.TenantId = t.TenantId and ta.Tag = t.Id
	where ta.Agent = @Id and ta.TenantId = @TenantId;

	exec cat.[Tag.For] @TenantId =@TenantId, @UserId = @UserId, @For = N'Agent';
end
go
-------------------------------------------------
drop procedure if exists cat.[Agent.Metadata];
drop procedure if exists cat.[Agent.Update];
drop type if exists cat.[Agent.TableType];
drop type if exists cat.[Agent.Contact.TableType];
go
-------------------------------------------------
create type cat.[Agent.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	IsCustomer bit,
	IsSupplier bit
)
go
------------------------------------------------
create type cat.[Agent.Contact.TableType]
as table (
	Id bigint null,
	Position nvarchar(255)
);
go
------------------------------------------------
create or alter procedure cat.[Agent.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Agent cat.[Agent.TableType];
	declare @Contacts cat.[Agent.Contact.TableType];
	declare @Tag a2sys.[Id.TableType];
	select [Agent!Agent!Metadata] = null, * from @Agent;
	select [Tags!Agent.Tags!Metadata] = null, * from @Tag;
	select [Contacts!Agent.Contacts!Metadata] = null, * from @Contacts;
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Update]
@TenantId int = 1,
@UserId bigint,
@Agent cat.[Agent.TableType] readonly, 
@Contacts cat.[Agent.Contact.TableType] readonly,
@Tags a2sys.[Id.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Tags for xml auto);
	throw 60000, @xml, 0;
	*/

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Agents as t
	using @Agent as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[FullName] = s.[FullName],
		t.IsCustomer = s.IsCustomer,
		t.IsSupplier = s.IsSupplier,
		t.[Partner] = 1
	when not matched by target then insert
		(TenantId, [Name], FullName, Memo, IsCustomer, IsSupplier, [Partner]) values
		(@TenantId, s.[Name], s.FullName, s.Memo, s.IsCustomer, s.IsSupplier, 1)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	with CT as (
		select * from cat.AgentContacts where TenantId=@TenantId and Agent = @id
	)
	merge CT as t
	using @Contacts as s
	on t.TenantId = @TenantId and t.Contact = s.Id
	--when matched then update
	when not matched by target then insert
		(TenantId, Agent, Contact) values
		(@TenantId, @id, s.Id)
	when not matched by source then delete;

	with TT as (
		select * from cat.TagsAgent where TenantId = @TenantId and Agent = @id
	)
	merge TT as t
	using @Tags as s
	on t.TenantId = @TenantId and t.Tag = s.Id
	when not matched by target then insert
		(TenantId, Agent, Tag) values
		(@TenantId, @id, s.Id)
	when not matched by source and t.Agent = @id and t.TenantId = @TenantId
	then delete;

	exec cat.[Agent.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Agents!TAgent!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name], a.Memo, a.FullName
	from cat.Agents a
	where TenantId = @TenantId and Void = 0 and a.[Partner] = 1 and
		([Name] like @fr or Memo like @fr or FullName like @fr)
	order by a.[Name];
end
go

/* Person */
-------------------------------------------------
create or alter procedure cat.[Person.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Persons!TPerson!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo]
	from cat.Agents a
	where TenantId = @TenantId and [Person] = 1
end
go
-------------------------------------------------
create or alter procedure cat.[Person.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Person!TPerson!Object] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo]
	from cat.Agents a
	where TenantId = @TenantId and Id = @Id and [Person] = 1;
end
go
-------------------------------------------------
drop procedure if exists cat.[Person.Metadata];
drop procedure if exists cat.[Person.Update];
drop type if exists cat.[Person.TableType];
go
-------------------------------------------------
create type cat.[Person.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Person.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Person cat.[Person.TableType];
	select [Person!Person!Metadata] = null, * from @Person;
end
go
------------------------------------------------
create or alter procedure cat.[Person.Update]
@TenantId int = 1,
@UserId bigint,
@Person cat.[Person.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Agents as t
	using @Person as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[FullName] = s.[FullName],
		t.[Person] = 1
	when not matched by target then insert
		(TenantId, [Name], FullName, Memo, [Person]) values
		(@TenantId, s.[Name], s.FullName, s.Memo, 1)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Person.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

------------------------------------------------
create or alter procedure cat.[Person.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Person!TPerson!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name], a.Memo, a.FullName
	from cat.Agents a
	where TenantId = @TenantId and Void = 0 and a.Person = 1 and
		([Name] like @fr or Memo like @fr or FullName like @fr)
	order by a.[Name];
end
go

-- CONTRACT
drop procedure if exists doc.[Contract.Maps];
drop type if exists doc.[Contract.Index.TableType]
go
-------------------------------------------------
create type doc.[Contract.Index.TableType] as table
(
	rowno int identity(1, 1), 
	id bigint, 
	agent bigint, 
	comp bigint, 
	pkind bigint, 
	kind nvarchar(16), 
	rowcnt int
);
go
-------------------------------------------------
create or alter procedure doc.[Contract.Maps]
@TenantId int = 1,
@Elems doc.[Contract.Index.TableType] readonly
as
begin
	-- maps
	with T as (select agent from @Elems group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with T as (select comp from @Elems group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	with T as (select pkind from @Elems group by pkind)
	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk 
		inner join T t on pk.TenantId = @TenantId and pk.Id = pkind;

	with T as (select kind from @Elems group by kind)
	select [!TContractKind!Map] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from doc.ContractKinds ck 
		inner join T t on ck.TenantId = @TenantId and ck.Id = kind;
end
go
-------------------------------------------------
create or alter procedure doc.[Contract.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Agent bigint = null,
@Company bigint = null,
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';

	declare @cnts doc.[Contract.Index.TableType];

	insert into @cnts(id, agent, comp, pkind, kind, rowcnt)
	select c.Id, c.Agent, c.Company, c.PriceKind, c.Kind,
		count(*) over()
	from doc.Contracts c
	where c.TenantId = @TenantId and c.Void = 0
		and (@Agent is null or c.Agent = @Agent)
		and (@Company is null or c.Company = @Company)
		and (@fr is null or c.[Name] like @fr or c.[SNo] like @fr or c.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'date' then c.[Date]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'sno' then c.[SNo]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'date' then c.[Date]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'sno' then c.[SNo]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Contracts!TContract!Array] = null, [Id!!Id] = c.Id, c.[Date], [Name!!Name] = c.[Name], c.[Memo], c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company,
		[PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TContractKind!RefId] = c.Kind,
		[!!RowCount] = t.rowcnt
	from @cnts t inner join 
		doc.Contracts c on c.TenantId = @TenantId and c.Id = t.id
	order by t.rowno;

	-- maps
	exec doc.[Contract.Maps] @TenantId, @cnts;

	select [!$System!] = null, [!Contracts!Offset] = @Offset, [!Contracts!PageSize] = @PageSize, 
		[!Contracts!SortOrder] = @Order, [!Contracts!SortDir] = @Dir,
		[!Contracts.Agent.Id!Filter] = @Agent, [!Contracts.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent),
		[!Contracts.Company.Id!Filter] = @Company, [!Contracts.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!Contracts.Fragment!Filter] = @Fragment;
end
go
-------------------------------------------------
create or alter procedure doc.[Contract.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Contract!TContract!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Date], c.Memo, c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company, [PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TContractKind!RefId] = c.Kind
	from doc.Contracts c
	where c.TenantId = @TenantId and c.Id = @Id;

	-- maps
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Contracts c on c.TenantId = a.TenantId and c.Agent = a.Id
	where c.Id = @Id and c.TenantId = @TenantId;


	select [!TCompany!Map] = null, [Id!!Id] = cmp.Id, [Name!!Name] = cmp.[Name]
	from cat.Companies cmp inner join doc.Contracts c on cmp.TenantId = c.TenantId and c.Company = cmp.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk inner join doc.Contracts c on pk.TenantId = c.TenantId and c.PriceKind = pk.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [ContractKinds!TContractKind!Array] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from doc.ContractKinds ck
	where ck.TenantId = @TenantId order by [Order];

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [Params!TParam!Object] = null, 
		[Agent.Id!TAgent!Id] = @Agent, [Agent.Name!TAgent!Name] = cat.fn_GetAgentName(@TenantId, @Agent),
		[Company.Id!TCompany!Id] =@Company, [Company.Name!TCompany!Name] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
-------------------------------------------------
drop procedure if exists doc.[Contract.Metadata];
drop procedure if exists doc.[Contract.Update];
drop type if exists doc.[Contract.TableType];
go
-------------------------------------------------
create type doc.[Contract.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	SNo nvarchar(255),
	[Date] date,
	Company bigint,
	Agent bigint,
	PriceKind bigint,
	Kind nvarchar(16)
)
go
------------------------------------------------
create or alter procedure doc.[Contract.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Contract doc.[Contract.TableType];
	select [Contract!Contract!Metadata] = null, * from @Contract;
end
go
------------------------------------------------
create or alter procedure doc.[Contract.Update]
@TenantId int = 1,
@UserId bigint,
@Contract doc.[Contract.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge doc.Contracts as t
	using @Contract as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Date] = s.[Date],
		t.SNo =  s.SNo,
		t.Company = s.Company,
		t.Agent = s.Agent,
		t.PriceKind = s.PriceKind,
		t.Kind = s.Kind
	when not matched by target then insert
		(TenantId, [Name], Memo, [Date], SNo, Company, Agent, PriceKind, Kind) values
		(@TenantId, s.[Name], s.Memo, s.[Date], s.[SNo], s.Company, s.Agent, s.PriceKind, s.Kind)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec doc.[Contract.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

-------------------------------------------------
create or alter procedure doc.[Contract.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update doc.Contracts set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

-------------------------------------------------
create or alter procedure doc.[Contract.Show.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Contract!TContract!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Date], c.Memo, c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company, [PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TContractKind!RefId] = c.Kind,
		[Documents!TDocument!LazyArray] = null
	from doc.Contracts c
	where c.TenantId = @TenantId and c.Id = @Id;

	-- maps
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Contracts c on c.TenantId = a.TenantId and c.Agent = a.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [!TCompany!Map] = null, [Id!!Id] = cmp.Id, [Name!!Name] = cmp.[Name]
	from cat.Companies cmp inner join doc.Contracts c on cmp.TenantId = c.TenantId and c.Company = cmp.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk inner join doc.Contracts c on pk.TenantId = c.TenantId and c.PriceKind = pk.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [!TContractKind!Array] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from doc.ContractKinds ck inner join doc.Contracts c on ck.TenantId = c.TenantId and c.Kind = ck.Id
	where ck.TenantId = @TenantId order by [Order];

	-- declarations
	select [Documents!TDocument!Array] = null, [Id!!Id] = Id, [Date], [No], SNo, [Sum], Memo, Done,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company, [Operation!TOperation!RefId] = d.Operation
	from doc.Documents d
	where d.TenantId = @TenantId and 1 <> 1;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o 
		where o.TenantId = @TenantId and 0 <> 0;
end
go
-------------------------------------------------
create or alter procedure doc.[Contract.Show.Documents]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'desc',
@Agent bigint = null,
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

	declare @docs table(doc bigint, agent bigint, company bigint, operation bigint, rowcnt int)
	insert into @docs(doc, agent, company, operation, rowcnt)
	select d.Id, d.Agent, d.Company, d.Operation,
		count(*) over()
	from doc.Documents d 
	where d.TenantId = @TenantId and d.[Contract] = @Id
		and (d.[Date] >= @From and d.[Date] < @end)
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

	select [Documents!TDocument!Array] = null, [Id!!Id] = Id, [Date], [No], SNo, [Sum], Memo, Done,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company, [Operation!TOperation!RefId] = d.Operation,
		[!!RowCount] = t.rowcnt
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and d.Id = t.doc;

	-- maps
	with TA as(select agent from @docs group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA on a.TenantId = @TenantId and a.Id = TA.agent;

	with TC as(select company from @docs group by company)
	select [!TCompany!Map] = null, [Id!!Id] = Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join TC on c.TenantId = @TenantId and c.Id = TC.company;

	with T as (select operation from @docs group by operation)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o 
		inner join T t on o.TenantId = @TenantId and o.Id = operation;

	select [!$System!] = null, [!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To;
end
go

-------------------------------------------------
create or alter procedure doc.[Contract.Fetch]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	set @Company = nullif(@Company, 0);
	set @Agent = nullif(@Agent, 0);

	declare @cnts doc.[Contract.Index.TableType];

	insert into @cnts(id, agent, comp, pkind, kind)
	select top(100) c.Id, c.Agent, c.Company, c.PriceKind, c.Kind
	from doc.Contracts c
	where c.TenantId = @TenantId and c.Void = 0
		and (@Agent is null or c.Agent = @Agent)
		and (@Company is null or c.Company = @Company)
		and (c.[Name] like @fr or c.[SNo] like @fr or c.Memo like @fr);

	select [Contracts!TContract!Array] = null, [Id!!Id] = c.Id, c.[Date], [Name!!Name] = c.[Name], c.[Memo], c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company,
		[PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TContractKind!RefId] = c.Kind
	from @cnts t inner join 
		doc.Contracts c on c.TenantId = @TenantId and c.Id = t.id;

	-- maps
	exec doc.[Contract.Maps] @TenantId, @cnts;

end
go

-- Contact
drop procedure if exists cat.[Contact.Maps];
drop type if exists cat.[Contact.Index.TableType]
go
-------------------------------------------------
create type cat.[Contact.Index.TableType] as table
(
	rowno int identity(1, 1), 
	id bigint, 
	rowcnt int
);
go
-------------------------------------------------
create or alter procedure cat.[Contact.Maps]
@TenantId int = 1,
@Elems cat.[Contact.Index.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	-- maps
	/*
	with T as (select agent from @Elems group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with T as (select comp from @Elems group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	with T as (select pkind from @Elems group by pkind)
	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk 
		inner join T t on pk.TenantId = @TenantId and pk.Id = pkind;

	with T as (select kind from @Elems group by kind)
	select [!TContactKind!Map] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from cat.ContactKinds ck 
		inner join T t on ck.TenantId = @TenantId and ck.Id = kind;
	*/
end
go
-------------------------------------------------
create or alter procedure cat.[Contact.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
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

	declare @cnts cat.[Contact.Index.TableType];

	insert into @cnts(id, rowcnt)
	select c.Id,
		count(*) over()
	from cat.Contacts c
	where c.TenantId = @TenantId and c.Void = 0
		and (@fr is null or c.[Name] like @fr or c.Memo like @fr or Email like @fr or 
		Phone like @fr or [Address] like @fr)
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
				when N'datecreated' then c.UtcDateCreated
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'datecreated' then c.UtcDateCreated
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Contacts!TContact!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Memo],
		c.Birthday, c.Gender, c.Position, c.Phone, c.Email, c.[Address],
		[!!RowCount] = t.rowcnt, [DateCreated!!UTC] = UtcDateCreated
	from @cnts t inner join 
		cat.Contacts c on c.TenantId = @TenantId and c.Id = t.id
	order by t.rowno;

	-- maps
	--exec cat.[Contact.Maps] @TenantId, @cnts;

	select [!$System!] = null, [!Contacts!Offset] = @Offset, [!Contacts!PageSize] = @PageSize, 
		[!Contacts!SortOrder] = @Order, [!Contacts!SortDir] = @Dir,
		[!Contacts.Fragment!Filter] = @Fragment;
end
go
-------------------------------------------------
create or alter procedure cat.[Contact.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Contact!TContact!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo,
		c.Position, c.Birthday, c.Phone, c.Email, c.[Address],
		[Leads!TLead!Array] = null
	from cat.Contacts c
	where c.TenantId = @TenantId and c.Id = @Id;

	select [!TLead!Array] = null, [Id!!Id] = l.Id, [Name!!Name] = l.[Name],
		[!TContact.Leads!ParentId] = l.Contact
	from crm.Leads l where l.Contact = @Id;
end
go
-------------------------------------------------
drop procedure if exists cat.[Contact.Metadata];
drop procedure if exists cat.[Contact.Update];
drop type if exists cat.[Contact.TableType];
go
-------------------------------------------------
create type cat.[Contact.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	Memo nvarchar(255),
	[Position] nvarchar(255),
	Gender nchar(1),
	Birthday date,
	Country nchar(3),
	Email nvarchar(64),
	Phone nvarchar(32),
	[Address] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Contact.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Contact cat.[Contact.TableType];
	select [Contact!Contact!Metadata] = null, * from @Contact;
end
go
------------------------------------------------
create or alter procedure cat.[Contact.Update]
@TenantId int = 1,
@UserId bigint,
@Contact cat.[Contact.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Contacts as t
	using @Contact as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.Position = s.Position,
		t.Gender = s.Gender,
		t.Phone = s.Phone,
		t.Email = s.Email,
		t.[Address] = s.[Address],
		t.UtcDateModified = getutcdate(),
		t.UserModified = @UserId
	when not matched by target then insert
		(TenantId, [Name], Memo, Position, Gender, Email, Phone, [Address],
			UserCreated, UserModified, UtcDateModified) values
		(@TenantId, s.[Name], s.Memo, Position, Gender, Email, Phone, [Address],
		    @UserId, @UserId, getutcdate())
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Contact.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

-------------------------------------------------
create or alter procedure cat.[Contact.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update cat.Contacts set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

-------------------------------------------------
create or alter procedure cat.[Contact.Fetch]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	set @Company = nullif(@Company, 0);
	set @Agent = nullif(@Agent, 0);

	declare @cnts cat.[Contact.Index.TableType];

	insert into @cnts(id)
	select top(100) c.Id	
	from cat.Contacts c
	where c.TenantId = @TenantId and c.Void = 0
		and (c.[Name] like @fr or c.Memo like @fr);

	select [Contacts!TContact!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Memo],
		c.Birthday, c.Gender, c.Position
	from @cnts t inner join 
		cat.Contacts c on c.TenantId = @TenantId and c.Id = t.id;
	-- maps
	exec cat.[Contact.Maps] @TenantId, @cnts;

end
go

/* BANK */
------------------------------------------------
create or alter procedure cat.[Bank.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
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
	set @fr = N'%' + @Fragment + N'%';
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
	where TenantId = @TenantId and b.Void = 0 and (@fr is null or b.BankCode like @fr or b.Code like @fr 
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
------------------------------------------------
create or alter procedure cat.[Bank.FindByCode]
@TenantId int = 1,
@UserId bigint,
@Code nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Bank!TBank!Object] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo, b.[Code], b.FullName, b.BankCode
	from cat.Banks b
	where TenantId = @TenantId and b.BankCode = @Code;
end
go
------------------------------------------------
create or alter procedure cat.[Bank.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select [Banks!TBank!Array] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.BankCode
	from cat.Banks b
	where TenantId = @TenantId and (b.BankCode like @fr or b.[Name] like @fr);
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



/* Country */
------------------------------------------------
create or alter procedure cat.[Country.Index]
@TenantId int = 1,
@UserId bigint,
@Id nchar(3) = null,
@Offset int = 0,
@PageSize int = -1,
@Order nvarchar(32) = N'id',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	select [Countries!TCountry!Array] = null,
		[Id!!Id] = c.Code, [Name!!Name] = c.[Name], c.Memo, 
		c.Alpha3, c.Alpha2
	from cat.Countries c
	where TenantId = @TenantId
		and (@fr is null or c.Code like @fr or c.Alpha3 like @fr or c.Alpha2 like @fr 
		or c.[Name] like @fr or c.Memo like @fr)
	order by
		case when @Dir = N'asc' then
			case @Order
				when N'id' then c.[Code]
				when N'alpha3' then c.[Alpha3]
				when N'alpha2' then c.[Alpha2]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then c.[Code]
				when N'alpha3' then c.[Alpha3]
				when N'alpha2' then c.[Alpha2]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc;

	select [!$System!] = null, [!Countries!Offset] = @Offset, [!Countries!PageSize] = @PageSize, 
		[!Countries!SortOrder] = @Order, [!Countries!SortDir] = @Dir,
		[!Countries.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Country.Load]
@TenantId int = 1,
@UserId bigint,
@Id nchar(3) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Country!TCountry!Object] = null,
		[Id!!Id] = c.Code, [Name!!Name] = c.[Name], c.Memo, c.Alpha2, c.Alpha3
	from cat.Countries c
	where c.TenantId = @TenantId and c.Code = @Id;
end
go
------------------------------------------------
drop procedure if exists cat.[Country.Metadata];
drop procedure if exists cat.[Country.Download.Metadata];
drop procedure if exists cat.[Country.Update];
drop procedure if exists cat.[Country.Download.Update];
drop type if exists cat.[Country.TableType];
go
------------------------------------------------
create type cat.[Country.TableType] as table
(
	Id nchar(3),
	[Alpha2] nchar(2),
	[Alpha3] nchar(3),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[Country.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Country cat.[Country.TableType];
	select [Country!Country!Metadata] = null, * from @Country;
end
go
---------------------------------------------
create or alter procedure cat.[Country.Update]
@TenantId int = 1,
@UserId bigint,
@Country cat.[Country.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id nchar(3));
	declare @id bigint;

	merge cat.Countries as t
	using @Country as s on (t.TenantId = @TenantId and t.Code = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[Alpha3] = s.[Alpha3],
		t.[Alpha2] = s.[Alpha2]
	when not matched by target then insert
		(TenantId, Code, [Name], Memo, Alpha2, Alpha3) values
		(@TenantId, Id, [Name], Memo, Alpha2, Alpha3)
	output $action, inserted.Code into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Country.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[Country.Delete]
@TenantId int = 1,
@UserId bigint,
@Id nchar(3)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from cat.Items where TenantId = @TenantId and Country = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.Countries set Void = 1 where TenantId = @TenantId and Code=@Id;
end
go
------------------------------------------------
create or alter procedure cat.[Country.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Countries!TCountry!Array] = null, [Id!!Id] = c.Code, [Name!!Name] = c.[Name], 
		c.[Alpha2], c.[Alpha3]
	from cat.Countries c 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or [Alpha3] like @fr or [Alpha2] like @fr)
	order by c.[Code];
end
go
------------------------------------------------
create or alter procedure cat.[Country.Download.Load]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Countries!TCountry!Array] = null, [Id!!Id] = Code, [Name!!Name] = [Name], Alpha2, Alpha3, Memo
	from cat.Countries c
	where c.TenantId = @TenantId and 1 <> 1;

	select [$Countries!TCountry!Array] = null, [Id!!Id] = Code, [Name!!Name] = [Name], Alpha2, Alpha3, Memo
	from cat.Countries c
	where c.TenantId = @TenantId and 1 <> 1;
end
go
---------------------------------------------
create or alter procedure cat.[Country.Download.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Country cat.[Country.TableType];
	select [Countries!Countries!Metadata] = null, * from @Country;
end
go
---------------------------------------------
create or alter procedure cat.[Country.Download.Update]
@TenantId int = 1,
@UserId bigint,
@Countries cat.[Country.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @id bigint;

	merge cat.Countries as t
	using @Countries as s on (t.TenantId = @TenantId and t.Code = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[Alpha3] = s.[Alpha3],
		t.[Alpha2] = s.[Alpha2],
		t.Void = 0
	when not matched by target then insert
		(TenantId, Code, [Name], Memo, Alpha2, Alpha3) values
		(@TenantId, Id, [Name], Memo, Alpha2, Alpha3);
end
go

/* BANK ACCOUNT*/
------------------------------------------------
create or alter procedure cat.[BankAccount.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @ba table(rowno int identity(1, 1), id bigint, comp bigint, bank bigint, 
		crc bigint, rowcnt int, balance money);

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	insert into @ba(id, comp, bank, crc, balance, rowcnt)
	select b.Id, b.Company, b.Bank, b.Currency, isnull(cr.[Sum], 0),
		count(*) over ()
	from cat.CashAccounts b
		left join jrn.CashReminders cr on  b.TenantId = cr.TenantId and cr.CashAccount = b.Id
		left join cat.Banks bnk on bnk.TenantId = b.TenantId and bnk.Id = b.Bank
	where b.TenantId = @TenantId and b.IsCashAccount = 0 
		and (@Company is null or b.Company = @Company)
		and (@fr is null or b.[Name] like @fr or b.Memo like @fr or bnk.[Name] like @fr)
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
				when N'balance' then cr.[Sum]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then b.[Id]
				when N'balance' then cr.[Sum]
			end
		end desc,
		b.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [BankAccounts!TBankAccount!Array] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo, Balance = t.balance,
		[Company!TCompany!RefId] = ba.Company,
		[Currency!TCurrency!RefId] = ba.Currency,
		[ItemRole!TItemRole!RefId] = ba.ItemRole,
		[Bank!TBank!RefId] = ba.Bank,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.CashAccounts ba on t.id  = ba.Id and ba.TenantId = @TenantId
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

	with T as(select crc from @ba group by crc)
	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Alpha3
	from cat.Currencies c inner join T on c.TenantId = @TenantId and c.Id = T.crc;

	with T as(select bank from @ba group by bank)
	select [!TBank!Map] = null, [Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.BankCode
	from cat.Banks b inner join T on b.TenantId = @TenantId and b.Id = T.bank;

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money' and ir.ExType = N'B';

	select [!$System!] = null, [!BankAccounts!Offset] = @Offset, [!BankAccounts!PageSize] = @PageSize, 
		[!BankAccounts!SortOrder] = @Order, [!BankAccounts!SortDir] = @Dir,
		[!BankAccounts.Company.Id!Filter] = @Company, [!BankAccounts.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
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
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo,
		[ItemRole!TItemRole!RefId] = ba.ItemRole,
		Balance = cr.[Sum]
	from cat.CashAccounts ba
		left join jrn.CashReminders cr on  ba.TenantId = cr.TenantId and cr.CashAccount = ba.Id
	where ba.TenantId = @TenantId and (@Company is null or Company = @Company) and ba.IsCashAccount = 0;

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money' and ir.ExType = N'B';

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
		[Bank!TBank!RefId] = ba.Bank, [ItemRole!TItemRole!RefId] = ba.ItemRole,
		Balance = cr.[Sum]
	from cat.CashAccounts ba
		left join jrn.CashReminders cr on  ba.TenantId = cr.TenantId and cr.CashAccount = ba.Id
	where ba.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join cat.CashAccounts ba on c.TenantId = ba.TenantId and ba.Company = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, c.Short, c.Alpha3
	from cat.Currencies c inner join cat.CashAccounts ba on c.TenantId = ba.TenantId and ba.Currency = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TBank!Map] = null, [Id!!Id] = b.Id, b.BankCode, b.[Name]
	from cat.Banks b inner join cat.CashAccounts ba on b.TenantId = ba.TenantId and ba.Bank = b.Id
	where b.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money' and ir.ExType = N'B';

	-- TODO: // BASE Currency!
	select [Params!TParam!Object] = null, [Currency.Id!TCurrency!Id] = c.Id, 
		[Currency.Short!TCurrency!] = c.Short, [Currency.Alpha3!TCurrency!] = c.Alpha3
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
	Bank bigint,
	ItemRole bigint
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
		t.Bank = s.Bank,
		t.ItemRole = s.ItemRole
	when not matched by target then insert
		(TenantId, IsCashAccount, ItemRole, Company, [Name], AccountNo, Currency, Bank, Memo) values
		(@TenantId, 0, s.ItemRole, s.Company, s.[Name], s.AccountNo, s.Currency, s.Bank, s.Memo)
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
@Id bigint = null,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @ba table(rowno int identity(1, 1), id bigint, comp bigint, 
		crc bigint, rowcnt int, balance money);

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	insert into @ba(id, comp, crc, balance, rowcnt)
	select c.Id, c.Company, c.Currency, isnull(cr.[Sum], 0),
		count(*) over ()
	from cat.CashAccounts c
		left join jrn.CashReminders cr on  c.TenantId = cr.TenantId and cr.CashAccount = c.Id
	where c.TenantId = @TenantId and c.IsCashAccount = 1
		and (@Company is null or c.Company = @Company)
		and (@fr is null or c.[Name] like @fr or c.Memo like @fr)
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
				when N'balance' then cr.[Sum]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then c.[Id]
				when N'balance' then cr.[Sum]
			end
		end desc,
		c.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo, Balance = isnull(t.balance, 0),
		[Company!TCompany!RefId] = ca.Company,
		[Currency!TCurrency!RefId] = ca.Currency,
		[ItemRole!TItemRole!RefId] = ca.ItemRole,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.CashAccounts ca on t.id  = ca.Id and ca.TenantId = @TenantId and ca.IsCashAccount = 1
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

	with T as(select crc from @ba group by crc)
	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Alpha3
	from cat.Currencies c inner join T on c.TenantId = @TenantId and c.Id = T.crc;

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money' and ir.ExType = N'C';

	select [!$System!] = null, [!CashAccounts!Offset] = @Offset, [!CashAccounts!PageSize] = @PageSize, 
		[!CashAccounts!SortOrder] = @Order, [!CashAccounts!SortDir] = @Dir,
		[!CashAccounts.Company.Id!Filter] = @Company, [!CashAccounts.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!CashAccounts.Fragment!Filter] = @Fragment;
end
go
------------------------------------------------
create or alter procedure cat.[CashAccount.Simple.Index]
@TenantId int = 1,
@UserId bigint,
@Company bigint = null,
@Id bigint = null,
@Mode nvarchar(16) = N'All',
@Date date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = isnull(ca.[Name], ca.AccountNo),  ca.AccountNo, ca.Memo, 
		[Balance] = isnull(cr.[Sum], 0),
		[Currency!TCurrency!RefId] = ca.Currency,
		[ItemRole!TItemRole!RefId] = ca.ItemRole
	from cat.CashAccounts ca
		left join jrn.CashReminders cr on ca.TenantId = cr.TenantId and cr.CashAccount = ca.Id
	where ca.TenantId = @TenantId and (@Company is null or ca.Company = @Company) and 
		(@Mode = N'All' or @Mode = N'Cash' and ca.IsCashAccount = 1 or @Mode = N'Bank' and ca.IsCashAccount = 0)
	order by ca.IsCashAccount, ca.[Name];

	select [!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money';

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Alpha3
	from cat.Currencies c inner join cat.CashAccounts ca on c.TenantId = ca.TenantId and c.Id = ca.Currency;

	select [Company!TCompany!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Companies where TenantId = @TenantId and Id=@Company;

	select [Params!TParam!Object] = null, [Mode] = @Mode;
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
		[Currency!TCurrency!RefId] = ca.Currency,
		[ItemRole!TItemRole!RefId] = ca.ItemRole,
		[Balance] = cr.[Sum]
	from cat.CashAccounts ca
		left join jrn.CashReminders cr on ca.TenantId = cr.TenantId and cr.CashAccount = ca.Id
	where ca.TenantId = @TenantId and ca.Id = @Id and ca.IsCashAccount = 1;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join cat.CashAccounts ca on c.TenantId = ca.TenantId and ca.Company = c.Id
	where c.TenantId = @TenantId and ca.Id = @Id;

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, c.Short, c.Alpha3
	from cat.Currencies c inner join cat.CashAccounts ca on c.TenantId = ca.TenantId and ca.Currency = c.Id
	where c.TenantId = @TenantId and ca.Id = @Id;

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money' and ir.ExType = N'C';

	-- TODO: // BASE Currency!
	select [Params!TParam!Object] = null, [Currency.Id!TCurrency!Id] = c.Id, 
		[Currency.Short!TCurrency!] = c.Short, [Currency.Alpha3!TCurrency!] = c.Alpha3
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
	Currency bigint,
	ItemRole bigint
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
		t.Currency = s.Currency,
		t.ItemRole = s.ItemRole
	when not matched by target then insert
		(TenantId, IsCashAccount, ItemRole, Company, [Name], Currency, Memo) values
		(@TenantId, 1, s.ItemRole, s.Company, s.[Name], s.Currency, s.Memo)
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
------------------------------------------------
create or alter procedure cat.[CashAccount.Fetch.Simple]
@TenantId int = 1,
@UserId bigint,
@Company bigint = null,
@Mode nvarchar(16) = N'All',
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';
	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = isnull(ca.[Name], ca.AccountNo),  ca.AccountNo, ca.Memo,
		[ItemRole!TItemRole!RefId] = ca.ItemRole
	from cat.CashAccounts ca
	where ca.TenantId = @TenantId and (@Company is null or ca.Company = @Company) and 
		(@Mode = N'All' or @Mode = N'Cash' and ca.IsCashAccount = 1 or @Mode = N'Bank' and ca.IsCashAccount = 0) and
		([Name] like @fr or AccountNo like @fr or ca.Memo like @fr)
	order by ca.IsCashAccount, ca.[Name];

	select [!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money';

end
go

/* ACCOUNT KIND */
drop procedure if exists acc.[AccKind.Metadata];
drop procedure if exists acc.[AccKind.Update];
drop type if exists acc.[AccKind.TableType];
go
------------------------------------------------
create type acc.[AccKind.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure acc.[AccKind.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [AccKinds!TAccKind!Array] = null,
		[Id!!Id] = ak.Id, [Name!!Name] = ak.[Name], ak.Memo
	from acc.AccKinds ak
	where ak.TenantId = @TenantId and ak.Void = 0
	order by ak.Id;
end
go
------------------------------------------------
create or alter procedure acc.[AccKind.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [AccKind!TAccKind!Object] = null,
		[Id!!Id] = ak.Id, [Name!!Name] = ak.[Name], ak.Memo
	from acc.AccKinds ak
	where ak.TenantId = @TenantId and ak.Id = @Id;
end
go
---------------------------------------------
create or alter procedure acc.[AccKind.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @AccKind acc.[AccKind.TableType];
	select [AccKind!AccKind!Metadata] = null, * from @AccKind;
end
go
---------------------------------------------
create or alter procedure acc.[AccKind.Update]
@TenantId int = 1,
@UserId bigint,
@AccKind acc.[AccKind.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge acc.AccKinds as t
	using @AccKind as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec acc.[AccKind.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure acc.[AccKind.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update acc.AccKinds set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go


/* ITEM ROLE */
drop procedure if exists cat.[ItemRole.Metadata];
drop procedure if exists cat.[ItemRole.Update];
drop type if exists cat.[ItemRole.TableType];
drop type if exists cat.[ItemRoleAccount.TableType];
go
------------------------------------------------
create type cat.[ItemRole.TableType] as table
(
	Id bigint,
	[Kind] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Color] nvarchar(32),
	HasPrice bit,
	IsStock bit,
	ExType nchar(1),
	CostItem bigint
)
go
------------------------------------------------
create type cat.[ItemRoleAccount.TableType] as table
(
	Id bigint,
	[Plan] bigint,
	Account bigint,
	AccKind bigint
)
go
------------------------------------------------
create or alter procedure cat.[ItemRole.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Kind nvarchar(16) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [ItemRoles!TItemRole!Array] = null,
		[Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Kind, ir.Memo, ir.Color, ir.HasPrice, ir.IsStock, ir.ExType
	from cat.ItemRoles ir
	where ir.TenantId = @TenantId and ir.Void = 0 and
		(@Kind is null or ir.Kind = @Kind)
	order by ir.Kind, ir.Id;
end
go
------------------------------------------------
create or alter procedure cat.[ItemRole.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [ItemRole!TItemRole!Object] = null,
		[Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Memo, ir.Kind, ir.Color, ir.HasPrice, ir.IsStock, ir.ExType,
		[CostItem!TCostItem!RefId] = ir.CostItem,
		[Accounts!TRoleAccount!Array] = null
	from cat.ItemRoles ir
	where ir.TenantId = @TenantId and ir.Id = @Id;

	select [!TRoleAccount!Array] = null, [Id!!Id] = ira.Id, [Plan!TAccount!RefId] = ira.[Plan],
		[Account!TAccount!RefId] = ira.Account, [AccKind!TAccKind!RefId] = ira.AccKind,
		[!TItemRole.Accounts!ParentId] = ira.[Role]
	from cat.ItemRoleAccounts ira
	where ira.TenantId = @TenantId and ira.[Role] = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = a.Id, [Code] = a.Code, [Name!!Name] = a.[Name]
	from acc.Accounts a
		inner join cat.ItemRoleAccounts ira on a.TenantId = ira.TenantId and a.Id in (ira.[Plan], ira.[Account])
	where ira.TenantId = @TenantId and ira.[Role] = @Id
	group by a.Id, a.Code, a.[Name];

	select [!TCostItem!Map] = null, [Id!!Id] = ci.Id, [Name!!Name] = ci.[Name]
	from cat.CostItems ci
		inner join cat.ItemRoles ir on ci.TenantId = ir.TenantId and ir.CostItem = ci.Id
	where ci.TenantId = @TenantId and ir.Id = @Id;

	select [AccKinds!TAccKind!Array] = null, [Id!!Id] = ak.Id, [Name!!Name] = ak.[Name]
	from acc.AccKinds ak
	where ak.TenantId = @TenantId and ak.Void = 0;
end
go
---------------------------------------------
create or alter procedure cat.[ItemRole.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Role cat.[ItemRole.TableType];
	declare @Accounts cat.[ItemRoleAccount.TableType];
	select [ItemRole!ItemRole!Metadata] = null, * from @Role;
	select [Accounts!ItemRole.Accounts!Metadata] = null, * from @Accounts;
end
go
---------------------------------------------
create or alter procedure cat.[ItemRole.Update]
@TenantId int = 1,
@UserId bigint,
@ItemRole cat.[ItemRole.TableType] readonly,
@Accounts cat.[ItemRoleAccount.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.ItemRoles as t
	using @ItemRole as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Kind] = s.[Kind],
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Color = s.Color,
		t.HasPrice = s.HasPrice,
		t.IsStock = s.IsStock,
		t.ExType = s.ExType,
		t.CostItem = s.CostItem
	when not matched by target then insert
		(TenantId, Kind, [Name], Memo, Color, HasPrice, IsStock, ExType, CostItem) values
		(@TenantId, Kind, [Name], Memo, Color, HasPrice, IsStock, ExType, CostItem)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	
	merge cat.ItemRoleAccounts as t
	using @Accounts as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Plan] = s.[Plan],
		t.Account = s.Account,
		t.AccKind = s.AccKind
	when not matched by target then insert
		(TenantId, [Role], [Plan], Account, AccKind) values
		(@TenantId, @id, s.[Plan], s.Account, s.AccKind)
	when not matched by source and t.TenantId = @TenantId and t.[Role] = @id then delete;

	exec cat.[ItemRole.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[ItemRole.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.ItemRoles set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go


/* UNIT */
drop procedure if exists cat.[Unit.Metadata];
drop procedure if exists cat.[Unit.Update];
drop type if exists cat.[Unit.TableType];
go
------------------------------------------------
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
	where TenantId = @TenantId and Void = 0
	order by u.Id;
end
go
------------------------------------------------
create or alter procedure cat.[Unit.Catalog.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- TenantId = 0 => Catalog
	exec cat.[Unit.Index] @TenantId = 0, @UserId = @UserId, @Id = @Id;
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
---------------------------------------------
create or alter procedure cat.[Unit.AddFromCatalog]
@TenantId int = 1,
@UserId bigint,
@Ids nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	merge cat.Units as t
	using (
		select u.Id, u.Short, u.CodeUA, u.[Name] 
		from cat.Units u
			inner join string_split(@Ids, N',') t on u.TenantId = 0 and u.Id = t.[value]) as s
	on t.TenantId = @TenantId and t.CodeUA = s.CodeUA
	when matched then update set 
		Short = s.Short,
		[Name] = s.[Name],
		Void = 0
	when not matched by target then insert
		(TenantId, Short, CodeUA, [Name]) values
		(@TenantId, s.Short, s.CodeUA, s.[Name]);
end
go
---------------------------------------------
create or alter procedure cat.[Unit.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from doc.DocDetails where TenantId = @TenantId and Unit = @Id)
		or exists(select 1 from cat.Items where TenantId = @TenantId and Unit = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.Units set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[Unit.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Units!TUnit!Array] = null, [Id!!Id] = u.Id, [Name!!Name] = u.[Name], u.[Short]
	from cat.Units u 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or [Short] like @fr)
	order by u.[Short];
end
go

/* Vendor */
drop procedure if exists cat.[Vendor.Metadata];
drop procedure if exists cat.[Vendor.Update];
drop type if exists cat.[Vendor.TableType];
go
------------------------------------------------
create type cat.[Vendor.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Vendor.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
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
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	with T(Id, [RowCount], RowNo) as (
	select v.Id, count(*) over (),
		RowNo = row_number() over (order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then v.[Name]
				when N'memo' then v.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then v.[Name]
				when N'memo' then v.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then v.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then v.[Id]
			end
		end desc,
		v.Id
		)
	from cat.Vendors v
	where TenantId = @TenantId and Void = 0 and (@fr is null or v.[Name] like @fr or v.Memo like @fr))
	select [Vendors!TVendor!Array] = null,
		[Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Memo,
		[!!RowCount] = t.[RowCount]
	from cat.Vendors v
		inner join T t on t.Id = v.Id
	order by t.RowNo
	offset @Offset rows fetch next @PageSize rows only 
	option(recompile);

	select [!$System!] = null, [!Vendors!Offset] = @Offset, [!Vendors!PageSize] = @PageSize, 
		[!Vendors!SortOrder] = @Order, [!Vendors!SortDir] = @Dir,
		[!Vendors.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Vendor.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Vendor!TVendor!Object] = null,
		[Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Memo
	from cat.Vendors v
	where v.TenantId = @TenantId and v.Id = @Id;
end
go
---------------------------------------------
create or alter procedure cat.[Vendor.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Vendor cat.[Vendor.TableType];
	select [Vendor!Vendor!Metadata] = null, * from @Vendor;
end
go
---------------------------------------------
create or alter procedure cat.[Vendor.Update]
@TenantId int = 1,
@UserId bigint,
@Vendor cat.[Vendor.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Vendors as t
	using @Vendor as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Vendor.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Vendor.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from cat.Items where TenantId = @TenantId and Vendor = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.Vendors set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[Vendor.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Vendors!TVendor!Array] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Memo
	from cat.Vendors v 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by v.[Name];
end
go

/* Brand */
------------------------------------------------
create or alter procedure cat.[Brand.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
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
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	with T(Id, [RowCount], RowNo) as (
	select b.Id, count(*) over (),
		RowNo = row_number() over (order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
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
	from cat.Brands b
	where TenantId = @TenantId and Void = 0 and (@fr is null or b.[Name] like @fr or b.Memo like @fr))
	select [Brands!TBrand!Array] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo,
		[!!RowCount] = t.[RowCount]
	from cat.Brands b
		inner join T t on t.Id = b.Id and b.TenantId = @TenantId
	order by t.RowNo
	offset @Offset rows fetch next @PageSize rows only 
	option(recompile);

	select [!$System!] = null, [!Brands!Offset] = @Offset, [!Brands!PageSize] = @PageSize, 
		[!Brands!SortOrder] = @Order, [!Brands!SortDir] = @Dir,
		[!Brands.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Brand.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Brand!TBrand!Object] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo
	from cat.Brands b
	where b.TenantId = @TenantId and b.Id = @Id;
end
go
------------------------------------------------
drop procedure if exists cat.[Brand.Metadata];
drop procedure if exists cat.[Brand.Update];
drop type if exists cat.[Brand.TableType];
go
------------------------------------------------
create type cat.[Brand.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[Brand.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Brand cat.[Brand.TableType];
	select [Brand!Brand!Metadata] = null, * from @Brand;
end
go
---------------------------------------------
create or alter procedure cat.[Brand.Update]
@TenantId int = 1,
@UserId bigint,
@Brand cat.[Brand.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Brands as t
	using @Brand as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Brand.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Brand.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from cat.Items where TenantId = @TenantId and Brand = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.Brands set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[Brand.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Brands!TBrand!Array] = null, [Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo
	from cat.Brands b 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by b.[Name];
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
		c.Alpha3, c.Number3, c.Denom, c.[Symbol], c.Short
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
		[Id!!Id] = c.Id, [NewId] = c.Id, [Name!!Name] = c.[Name], c.Memo, c.Alpha3, c.Number3, c.Denom, c.Symbol,
		c.Short
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
	[Symbol] nvarchar(3),
	Short nvarchar(8)
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
		t.[Denom] = s.[Denom],
		t.[Short] = s.[Short]
	when not matched by target then insert
		(TenantId, Id, [Name], Memo, Alpha3, Number3, [Symbol], [Denom], [Short]) values
		(@TenantId, s.[NewId], s.[Name], s.Memo, s.Alpha3, s.Number3, s.[Symbol], s.Denom, s.[Short])
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

/* PRICEKINDS */
------------------------------------------------
drop procedure if exists cat.[PriceKind.Metadata];
drop procedure if exists cat.[PriceKind.Update];
drop type if exists cat.[PriceKind.TableType];
go
------------------------------------------------
create or alter procedure cat.[PriceKind.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PriceKinds!TPriceKind!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.PriceKinds pk
	where TenantId = @TenantId and Void = 0
	order by pk.Id;
end
go
------------------------------------------------
create or alter procedure cat.[PriceKind.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PriceKind!TPriceKind!Object] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.PriceKinds pk
	where TenantId = @TenantId and Id = @Id;
end
go
---------------------------------------------
create type cat.[PriceKind.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[PriceKind.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @PriceKind cat.[PriceKind.TableType];
	select [PriceKind!PriceKind!Metadata] = null, * from @PriceKind;
end
go
---------------------------------------------
create or alter procedure cat.[PriceKind.Update]
@TenantId int = 1,
@UserId bigint,
@PriceKind cat.[PriceKind.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.PriceKinds as t
	using @PriceKind as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[PriceKind.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[PriceKind.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.PriceKinds set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[PriceKind.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [PriceKinds!TPriceKind!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name], pk.Memo
	from cat.PriceKinds pk 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by pk.[Name];
end
go


/* CASHFLOWITEM */
------------------------------------------------
drop procedure if exists cat.[CashFlowItem.Metadata];
drop procedure if exists cat.[CashFlowItem.Update];
drop type if exists cat.[CashFlowItem.TableType];
go
------------------------------------------------
create or alter procedure cat.[CashFlowItem.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CashFlowItems!TCashFlowItem!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.CashFlowItems pk
	where TenantId = @TenantId and Void = 0
	order by pk.Id;
end
go
------------------------------------------------
create or alter procedure cat.[CashFlowItem.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CashFlowItem!TCashFlowItem!Object] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.CashFlowItems pk
	where TenantId = @TenantId and Id = @Id;
end
go
---------------------------------------------
create type cat.[CashFlowItem.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[CashFlowItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @CashFlowItem cat.[CashFlowItem.TableType];
	select [CashFlowItem!CashFlowItem!Metadata] = null, * from @CashFlowItem;
end
go
---------------------------------------------
create or alter procedure cat.[CashFlowItem.Update]
@TenantId int = 1,
@UserId bigint,
@CashFlowItem cat.[CashFlowItem.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.CashFlowItems as t
	using @CashFlowItem as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[CashFlowItem.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[CashFlowItem.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.CashFlowItems set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[CashFlowItem.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [CashFlowItems!TCashFlowItem!Array] = null, [Id!!Id] = cfi.Id, [Name!!Name] = cfi.[Name], cfi.Memo
	from cat.CashFlowItems cfi 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by cfi.[Name];
end
go


/* COSTITEM */
------------------------------------------------
drop procedure if exists cat.[CostItem.Metadata];
drop procedure if exists cat.[CostItem.Update];
drop type if exists cat.[CostItem.TableType];
go
------------------------------------------------
create or alter procedure cat.[CostItem.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CostItems!TCostItem!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.CostItems pk
	where TenantId = @TenantId and Void = 0
	order by pk.Id;
end
go
------------------------------------------------
create or alter procedure cat.[CostItem.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CostItem!TCostItem!Object] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.CostItems pk
	where TenantId = @TenantId and Id = @Id;
end
go
---------------------------------------------
create type cat.[CostItem.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[CostItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @CostItem cat.[CostItem.TableType];
	select [CostItem!CostItem!Metadata] = null, * from @CostItem;
end
go
---------------------------------------------
create or alter procedure cat.[CostItem.Update]
@TenantId int = 1,
@UserId bigint,
@CostItem cat.[CostItem.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.CostItems as t
	using @CostItem as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[CostItem.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[CostItem.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.CostItems set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go



/* Project */
drop procedure if exists cat.[Project.Metadata];
drop procedure if exists cat.[Project.Update];
drop type if exists cat.[Project.TableType];
go
------------------------------------------------
create type cat.[Project.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Project.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
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
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	with T(Id, [RowCount], RowNo) as (
	select p.Id, count(*) over (),
		RowNo = row_number() over (order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then p.[Name]
				when N'memo' then p.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then p.[Name]
				when N'memo' then p.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then p.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then p.[Id]
			end
		end desc,
		p.Id
		)
	from cat.Projects p
	where TenantId = @TenantId and Void = 0 and (@fr is null or p.[Name] like @fr or p.Memo like @fr))
	select [Projects!TProject!Array] = null,
		[Id!!Id] = p.Id, [Name!!Name] = p.[Name], p.Memo,
		[!!RowCount] = t.[RowCount]
	from cat.Projects p
		inner join T t on t.Id = p.Id and p.TenantId = @TenantId
	order by t.RowNo
	offset @Offset rows fetch next @PageSize rows only 
	option(recompile);

	select [!$System!] = null, [!Projects!Offset] = @Offset, [!Projects!PageSize] = @PageSize, 
		[!Projects!SortOrder] = @Order, [!Projects!SortDir] = @Dir,
		[!Projects.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Project.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Project!TProject!Object] = null,
		[Id!!Id] = p.Id, [Name!!Name] = p.[Name], p.Memo
	from cat.Projects p
	where p.TenantId = @TenantId and p.Id = @Id;
end
go
---------------------------------------------
create or alter procedure cat.[Project.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Project cat.[Project.TableType];
	select [Project!Project!Metadata] = null, * from @Project;
end
go
---------------------------------------------
create or alter procedure cat.[Project.Update]
@TenantId int = 1,
@UserId bigint,
@Project cat.[Project.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Projects as t
	using @Project as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Project.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Project.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Projects set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[Project.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Projects!TProject!Array] = null, [Id!!Id] = p.Id, [Name!!Name] = p.[Name], p.Memo
	from cat.Projects p 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by p.[Name];
end
go

/* RESPCENTER */
------------------------------------------------
drop procedure if exists cat.[RespCenter.Metadata];
drop procedure if exists cat.[RespCenter.Update];
drop type if exists cat.[RespCenter.TableType];
go
------------------------------------------------
create or alter procedure cat.[RespCenter.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [RespCenters!TRespCenter!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.RespCenters pk
	where TenantId = @TenantId and Void = 0
	order by pk.Id;
end
go
------------------------------------------------
create or alter procedure cat.[RespCenter.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [RespCenter!TRespCenter!Object] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.RespCenters pk
	where TenantId = @TenantId and Id = @Id;
end
go
---------------------------------------------
create type cat.[RespCenter.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[RespCenter.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @RespCenter cat.[RespCenter.TableType];
	select [RespCenter!RespCenter!Metadata] = null, * from @RespCenter;
end
go
---------------------------------------------
create or alter procedure cat.[RespCenter.Update]
@TenantId int = 1,
@UserId bigint,
@RespCenter cat.[RespCenter.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.RespCenters as t
	using @RespCenter as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[RespCenter.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[RespCenter.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from doc.Documents where TenantId = @TenantId and RespCenter = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.RespCenters set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go
------------------------------------------------
create or alter procedure cat.[RespCenter.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [RespCenters!TRespCenter!Array] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name], r.Memo
	from cat.RespCenters r
	where TenantId = @TenantId and Void = 0 and
		([Name] like @fr or Memo like @fr)
	order by r.[Name];
end
go



/* ACCOUNT KIND */
drop procedure if exists doc.[Autonum.Metadata];
drop procedure if exists doc.[Autonum.Update];
drop type if exists doc.[Autonum.TableType];
go
------------------------------------------------
create type doc.[Autonum.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Period] nchar(1),
	Pattern nvarchar(255)
)
go
------------------------------------------------
create or alter procedure doc.[Autonum.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Autonums!TAutonum!Array] = null,
		[Id!!Id] = an.Id, [Name!!Name] = an.[Name], an.Memo, an.Pattern, an.[Period]
	from doc.Autonums an
	where an.TenantId = @TenantId and an.Void = 0
	order by an.Id;
end
go
------------------------------------------------
create or alter procedure doc.[Autonum.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Autonum!TAutonum!Object] = null,
		[Id!!Id] = an.Id, [Name!!Name] = an.[Name], an.Memo, an.[Period], an.Pattern
	from doc.Autonums an
	where an.TenantId = @TenantId and an.Id = @Id;
end
go
---------------------------------------------
create or alter procedure doc.[Autonum.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Autonum doc.[Autonum.TableType];
	select [Autonum!Autonum!Metadata] = null, * from @Autonum;
end
go
---------------------------------------------
create or alter procedure doc.[Autonum.Update]
@TenantId int = 1,
@UserId bigint,
@Autonum doc.[Autonum.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge doc.Autonums as t
	using @Autonum as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.[Period] = s.[Period],
		t.Pattern = s.[Pattern]
	when not matched by target then insert
		(TenantId, [Name], Memo, [Period], Pattern) values
		(@TenantId, [Name], Memo, [Period], Pattern)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec doc.[Autonum.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure doc.[Autonum.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update doc.Autonums set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go


/* ACCOUNT KIND */
drop procedure if exists doc.[DocState.Item.Metadata];
drop procedure if exists doc.[DocState.Item.Update];
drop procedure if exists doc.[DocState.Update]; -- temp
drop type if exists doc.[DocState.TableType];
go
------------------------------------------------
create type doc.[DocState.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Order] int,
	[Kind] nchar(1), -- (I)nit, (P)rocess, [S]uccess, C(ancel)
	[Memo] nvarchar(255),
	[Form] nvarchar(16)
)
go
------------------------------------------------
create or alter procedure doc.[DocState.Index]
@TenantId int = 1,
@UserId bigint,
@Id nvarchar(32) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Forms!TForm!Array] = null,
		[Id!!Id] = f.Id, [Name!!Name] = f.[Name], f.Memo,
		[States!TState!Array] = null
	from doc.Forms f
	where f.TenantId = @TenantId and f.HasState = 1
	order by f.[Order];

	select [!TState!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color,
		[!TForm.States!ParentId] = ds.Form
	from doc.DocStates ds
	where ds.TenantId = @TenantId and ds.Void = 0
	order by ds.[Order]
end
go
------------------------------------------------
create or alter procedure doc.[DocState.Load]
@TenantId int = 1,
@UserId bigint,
@Id nvarchar(32) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Form!TForm!MainObject] = null, [Id!!Id] = an.Id, [Name!!Name] = an.[Name], an.Memo,
		[States!TState!Array] = null
	from doc.Forms an
	where an.TenantId = @TenantId and an.Id = @Id;

	select [!TState!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color,
		[Order], [Kind], Memo,
		[!TForm.States!ParentId] = ds.Form
	from doc.DocStates ds
	where ds.TenantId = @TenantId and ds.Void = 0 and ds.Form = @Id
	order by ds.[Order];
end
go
------------------------------------------------
create or alter procedure doc.[DocState.Item.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Form nvarchar(16) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [State!TState!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color,
		[Order], [Kind], Memo, Form
	from doc.DocStates ds
	where ds.TenantId = @TenantId and ds.Void = 0 and ds.Id = @Id;

	select [Params!TParam!Object] = null, [NextOrdinal] = isnull(max([Order]), 0) + 1, Form = @Form
	from doc.DocStates
	where TenantId = @TenantId and Form = @Form;
end
go
---------------------------------------------
create or alter procedure doc.[DocState.Item.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @DocState doc.[DocState.TableType];
	select [State!State!Metadata] = null, * from @DocState;
end
go
---------------------------------------------
create or alter procedure doc.[DocState.Item.Update]
@TenantId int = 1,
@UserId bigint,
@State doc.[DocState.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge doc.DocStates as t
	using @State as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name],
		t.Memo = s.Memo,
		t.Color = s.Color,
		t.[Order] = s.[Order],
		t.Kind = s.Kind
	when not matched by target then insert
		(TenantId, Form, [Name], Memo, Color, [Order], Kind) values
		(@TenantId, [Form], [Name], Memo, Color, [Order], Kind)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec doc.[DocState.Item.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure doc.[DocState.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if @Id < 100
		throw 60000, N'UI:@[Error.Delete.System]', 0;
	if exists(select * from doc.Documents where [State] = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update doc.DocStates set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go


/* LeadStage */
drop procedure if exists crm.[LeadStage.Metadata];
drop procedure if exists crm.[LeadStage.Update];
drop type if exists crm.[LeadStage.TableType];
drop type if exists crm.[LeadStageAccount.TableType];
go
------------------------------------------------
create type crm.[LeadStage.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Memo] nvarchar(255),
	[Order] int,
	[Kind] nchar(1)
)
go
------------------------------------------------
create or alter procedure crm.[LeadStage.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Kind nvarchar(16) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Stages!TStage!Array] = null,
		[Id!!Id] = ls.Id, [Name!!Name] = ls.[Name], ls.Color, ls.[Order], ls.Memo, ls.Kind
	from crm.LeadStages ls
	where ls.TenantId = @TenantId and ls.Void = 0
	order by ls.[Order];
end
go
------------------------------------------------
create or alter procedure crm.[LeadStage.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Stage!TStage!Object] = null,
		[Id!!Id] = ls.Id, [Name!!Name] = ls.[Name], ls.Color, ls.[Order], ls.Memo, ls.Kind
	from crm.LeadStages ls
	where ls.TenantId = @TenantId and ls.Id = @Id;

	select [Params!TParam!Object] = null, [NextOrdinal] = isnull(max([Order]), 0) + 1
	from crm.LeadStages 
	where TenantId = @TenantId;
end
go
---------------------------------------------
create or alter procedure crm.[LeadStage.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Role crm.[LeadStage.TableType];
	select [Stage!Stage!Metadata] = null, * from @Role;
end
go
---------------------------------------------
create or alter procedure crm.[LeadStage.Update]
@TenantId int = 1,
@UserId bigint,
@Stage crm.[LeadStage.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge crm.LeadStages as t
	using @Stage as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.Color = s.Color,
		t.Memo = s.Memo,
		t.[Order] = s.[Order],
		t.Kind = s.Kind
	when not matched by target then insert
		(TenantId, [Name], Color, Memo, [Order], Kind) values
		(@TenantId, s.[Name], s.Color, s.Memo, s.[Order],s.Kind)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	
	exec crm.[LeadStage.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure crm.[LeadStage.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if @Id < 100
		throw 60000, N'UI:@[Error.Delete.System]', 0;
	if exists(select * from crm.Leads where Stage = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update crm.LeadStages set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go


/* DASHBOARD */
------------------------------------------------
create or alter procedure app.[Dashboard.Load]
@TenantId int = 1,
@UserId bigint,
@Kind nvarchar(16)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @id bigint;

	select @id = Id from app.Dashboards 
	where TenantId = @TenantId and [User] = @UserId and Kind = @Kind;
	if @@rowcount = 0
	begin
		insert into app.Dashboards (TenantId, [User], [Kind]) values (@TenantId, @UserId, @Kind);
		select @id = Id from app.Dashboards 
		where TenantId = @TenantId and [User] = @UserId and Kind = @Kind;
	end

	select [Dashboard!TDashboard!Object] = null, [Id!!Id] = d.Id, Kind,
		[Items!TDashboardItem!Array] = null, [Widgets!TWidget!LazyArray] = null
	from app.Dashboards d 
	where TenantId = @TenantId and [User] = @UserId and Kind = @Kind;

	select [!TDashboardItem!Array] = null, [Id!!Id] = di.Id, di.[row], di.[col], di.rowSpan, di.colSpan,
		di.Widget, w.[Url], [Params!!Json] = di.Params, [!TDashboard.Items!ParentId] = di.Dashboard
	from app.DashboardItems di 
	inner join app.Widgets w on di.TenantId = w.TenantId and di.Widget = w.Id
	where di.TenantId = @TenantId and di.Dashboard = @id;

	select [!TWidget!Array] = null, w.[Name], [row] = 0, col = 0, w.rowSpan, w.colSpan, w.[Url],
		[Widget] = w.Id, w.Icon, w.Memo, [Params], w.Kind, w.Category
	from app.Widgets w where 0 <> 0;
end
go
-------------------------------------------------
create or alter procedure app.[Dashboard.Widgets]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @kind nvarchar(16);
	select @kind = Kind from app.Dashboards where TenantId = @TenantId and Id = @Id;

	select [Widgets!TWidget!Array] = null, w.[Name], [row] = 0, col = 0, w.rowSpan, w.colSpan, w.[Url],
		[Widget] = w.Id, Icon, Memo, Params, w.Kind, w.Category
	from app.Widgets w 
	where w.TenantId = @TenantId and Kind = @kind
	order by w.Id;
end
go
-------------------------------------------------
drop procedure if exists app.[Dashboard.Metadata];
drop procedure if exists app.[Dashboard.Update];
drop type if exists app.[Dashboard.TableType];
drop type if exists app.[DashboardItem.TableType];
go
------------------------------------------------
create type app.[Dashboard.TableType] as table 
(
	Id bigint null,
	Kind nvarchar(16)
);
go
------------------------------------------------
create type app.[DashboardItem.TableType] as table
(
	Id bigint,
	[row] int,
	[col] int,
	Widget bigint,
	Params nvarchar(1023)
);
go
-------------------------------------------------
create or alter procedure app.[Dashboard.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @Dashboard app.[Dashboard.TableType];
	declare @Items app.[DashboardItem.TableType];

	select [Dashboard!Dashboard!Metadata] = null, * from @Dashboard;
	select [Items!Dashboard.Items!Metadata] = null, * from @Items;
end
go
-------------------------------------------------
create or alter procedure app.[Dashboard.Update]
@TenantId int = 1,
@UserId bigint,
@Dashboard app.[Dashboard.TableType] readonly,
@Items app.[DashboardItem.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @id bigint;
	declare @kind nvarchar(16);

	select @id = Id, @kind = Kind from @Dashboard;

	/*
	declare @xml nvarchar(max);
	select @xml = (select * from @Items for xml auto);
	throw 60000, @xml, 0;
	*/
	with T as (
		select Id = i.Id, i.[row], i.col, w.rowSpan, w.colSpan, Widget = i.Widget, i.Params
			from @Items i inner join app.Widgets w on w.TenantId = @TenantId and w.Id = i.Widget
	)
	merge app.DashboardItems as t
	using T as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[row] = s.[row],
		t.[col] = s.[col]
	when not matched by target then insert
		(TenantId, Dashboard, Widget, [row], col, rowSpan, colSpan, Params) values
		(@TenantId, @id, s.Widget, s.[row], s.[col], s.rowSpan, s.colSpan, s.Params)
	when not matched by source and t.TenantId = @TenantId and t.Dashboard = @id then delete;
	
	exec app.[Dashboard.Load] @TenantId = @TenantId, @UserId = @UserId, @Kind = @kind;
end
go

/* Accounting plan */
------------------------------------------------
create or alter procedure acc.[Accounting.Account.Index]
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
		[InitExpand!!Expanded] = case when T.[Level] < 1 then 1 else 0 end,
		[Items!TAccount!Items] = null, [!TAccount.Items!ParentId] = T.Parent,
		[Documents!TDocument!LazyArray] = null
	from T inner join acc.Accounts a on a.Id = T.Id and a.TenantId = @TenantId
	order by T.[Level], a.Code;

	-- declarations
	select [!TDocument!LazyArray] = null, [Id!!Id] = Id, [Date], [Sum], Memo,
		[Agent!TAgent!RefId] = Agent, [Company!TCompany!RefId] = Company,
		[Operation!TOperation!RefId] = Operation,
		[!!RowCount] = 0
	from doc.Documents where 1 <> 1;

	select [!TAgent!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Agents where 1 <> 1;

	select [!TCompany!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Companies where 1 <> 1;

	select [!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o where 1 <> 1;
end
go
------------------------------------------------
create or alter procedure acc.[Accounting.Account.Documents]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'desc',
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

	declare @docs table(doc bigint, agent bigint, company bigint, operation bigint, rowcnt int)
	insert into @docs(doc, agent, company, operation, rowcnt)
	select d.Id, d.Agent, d.Company, d.Operation,
		count(*) over()
	from jrn.Journal j
		inner join doc.Documents d on j.TenantId = d.TenantId and j.Document = d.Id
	where j.TenantId = @TenantId and j.Account = @Id
		and (j.[Date] >= @From and j.[Date] < @end)
	group by d.Id, d.Agent, d.Company, d.[Date], d.[Sum], d.Operation
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

	select [Documents!TDocument!Array] = null, [Id!!Id] = Id, [Date], [Sum], d.Memo,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[Operation!TOperation!RefId] = d.Operation,
		[!!RowCount] = t.rowcnt
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and t.doc = d.Id;

	-- maps
	with TA as(select agent from @docs group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA on a.TenantId = @TenantId and a.Id = TA.agent;

	with TC as(select company from @docs group by company)
	select [!TCompany!Map] = null, [Id!!Id] = Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join TC on c.TenantId = @TenantId and c.Id = TC.company;

	with T as (select operation from @docs group by operation)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o 
		inner join T t on o.TenantId = @TenantId and o.Id = operation;

	select [!$System!] = null, 
		[!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To;
		--[!Documents.Operation!Filter] = @Operation
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
		[Items!TAccount!Items] = null, [!TAccount.Items!ParentId] = T.Parent, 
		[InitExpand!!Expanded] = case when T.[Level] < 1 then 1 else 0 end
	from T inner join acc.Accounts a on a.Id = T.Id and a.TenantId = @TenantId
	order by T.[Level], a.Code;

	select [Settings!TSettings!Object] = null,
		[RemAccount!TAccount!RefId] = cast(10001 as bigint);
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
	select [Account!TAccount!Object] = null, [Id!!Id] = Id, Code, [Name], [Memo], [Plan], IsFolder
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
		ParentAccount = Parent, IsFolder, IsItem, IsWarehouse, IsAgent, IsBankAccount, IsCash, IsContract,
		IsCostItem, IsRespCenter
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
	IsContract bit,
	IsCostItem bit, 
	IsRespCenter bit
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
		t.IsContract = s.IsContract,
		t.IsCostItem = s.IsCostItem, 
		t.IsRespCenter = s.IsRespCenter
	when not matched by target then insert
		(TenantId, [Plan], Parent, Code, [Name], [Memo], IsFolder, IsItem, IsAgent, IsWarehouse, 
			IsBankAccount, IsCash, IsContract, IsCostItem, IsRespCenter) values
		(@TenantId, @plan, s.ParentAccount, s.Code, s.[Name], s.Memo, s.IsFolder, s.IsItem, s.IsAgent, s.IsWarehouse,
			s.IsBankAccount, s.IsCash, s.IsContract, s.IsCostItem, s.IsRespCenter)
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
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, [InitExpand!!Expanded] = 1
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
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, 
		[InitExpand!!Expanded] = case when T.[Level] < 1 then 1 else 0 end
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
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form!TForm!RefId] = o.Form, [Kind!TOpKind!RefId] = o.Kind,
		[Journals!TOpJournal!Array] = null
	from doc.Operations o
		inner join doc.Forms df on o.TenantId = df.TenantId and o.Form = df.Id
	where o.TenantId = @TenantId
	order by df.[Order], o.Id;

	select [Forms!TForm!Array] = null, [Id!!Id] = f.Id, [Name!!Name] = f.[Name], f.Category
	from doc.Forms f;

	select [Kinds!TOpKind!Array] = null, [Id!!Id] = ok.Id, [Name]
	from doc.OperationKinds ok
	where ok.TenantId = @TenantId
	order by ok.[Order];
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Index]
@TenantId int = 1,
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
create or alter procedure doc.[Operation.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;


	select [Operation!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		o.DocumentUrl, [Form!TForm!RefId] = o.Form, [Autonum!TAutonum!RefId] = o.Autonum,
		[Kind!TOpKind!RefId] = o.Kind,
		[OpLinks!TOpLink!Array] = null,
		[Trans!TOpTrans!Array] = null, [Store!TOpStore!Array] = null, 
		[Cash!TOpCash!Array] = null, [Settle!TOpSettle!Array] = null
	from doc.Operations o
	where o.TenantId = @TenantId and o.Id=@Id;

	-- ACCOUNT TRANSACTIONS
	select [!TOpTrans!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		[Plan!TAccount!RefId] = [Plan], [Dt!TAccount!RefId] = Dt, [Ct!TAccount!RefId] = Ct, 
		DtAccMode, DtSum, DtRow, CtAccMode, CtSum, CtRow, IsStorno = cast(case when ot.Factor = -1 then 1 else 0 end as bit),
		[!TOperation.Trans!ParentId] = ot.Operation,
		[DtAccKind!TAccKind!RefId] = ot.DtAccKind, [CtAccKind!TAccKind!RefId] = ot.CtAccKind
	from doc.OpTrans ot 
	where ot.TenantId = @TenantId and ot.Operation = @Id
	order by ot.RowNo;

	-- STORE TRANSACTIONS
	select [!TOpStore!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		os.IsIn, os.IsOut, IsStorno = cast(case when os.Factor = -1 then 1 else 0 end as bit), 
		[!TOperation.Store!ParentId] = os.Operation
	from doc.OpStore os
	where os.TenantId = @TenantId and os.Operation = @Id
	order by os.RowNo;

	-- CASH TRANSACTIONS
	select [!TOpCash!Array] = null, [Id!!Id] = Id,
		oc.IsIn, oc.IsOut, IsStorno = cast(case when oc.Factor = -1 then 1 else 0 end as bit), 
		[!TOperation.Cash!ParentId] = oc.Operation
	from doc.OpCash oc
	where oc.TenantId = @TenantId and oc.Operation = @Id;

	-- SETTLEMENT TRANSACTIONS
	select [!TOpSettle!Array] = null, [Id!!Id] = Id,
		os.IsInc, os.IsDec, IsStorno = cast(case when os.Factor = -1 then 1 else 0 end as bit), 
		[!TOperation.Settle!ParentId] = os.Operation
	from doc.OpSettle os
	where os.TenantId = @TenantId and os.Operation = @Id;

	select [!TOpLink!Array] = null, [Id!!Id] = ol.Id, [Type], [Category],
		[Operation.Id!TOper!Id] = o.Id, [Operation.Name!TOper!Name] = o.[Name],
		[!TOperation.OpLinks!ParentId] = ol.Parent
	from doc.OperationLinks ol 
		inner join doc.Operations o on ol.TenantId = o.TenantId and ol.Operation = o.Id
	where ol.TenantId = @TenantId and ol.Parent = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = a.Id, a.Code, [Name!!Name] = a.[Name],
		a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash
	from doc.OpTrans ot 
		left join acc.Accounts a on ot.TenantId = a.TenantId and a.Id in (ot.[Plan], ot.Dt, ot.Ct)
	where ot.TenantId = @TenantId and ot.Operation = @Id
	group by a.Id, a.Code, a.[Name], a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash;

	select [Forms!TForm!Array] = null, [Id!!Id] = df.Id, [Name!!Name] = df.[Name], [Category], InOut, [Url],
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

	select [PrintForms!TPrintForm!Array] = null, [Id!!Id] = pf.Id, [Name], pf.[Category], 
		Checked = case when pfl.PrintForm is not null then 1 else 0 end
	from doc.PrintForms pf
		left join doc.OpPrintForms pfl on pf.TenantId = pfl.TenantId and pfl.Operation = @Id and pf.Id = pfl.PrintForm
	where pf.TenantId = @TenantId
	order by pf.[Order];

	select [Autonums!TAutonum!Array] = null, [Id!!Id] = an.Id, [Name]
	from doc.Autonums an
	where an.TenantId = @TenantId and an.Void = 0
	order by an.[Name];


	select [!TRowKind!Array] = null, [Id!!Id] = rk.Id, [Name!!Name] = rk.[Name], [!TForm.RowKinds!ParentId] = rk.Form
	from doc.FormRowKinds rk where rk.TenantId = @TenantId
	order by rk.[Order];

	select [AccountKinds!TAccKind!Array] = null, [Id!!Id] = ak.Id, [Name!!Name] = ak.[Name]
	from acc.AccKinds ak
	where ak.TenantId = @TenantId
	order by ak.Id;

	select [Kinds!TOpKind!Array] = null, [Id!!Id] = ok.Id, [Name]
	from doc.OperationKinds ok
	where ok.TenantId = @TenantId
	order by ok.[Order];
end
go
-------------------------------------------------
drop procedure if exists doc.[Operation.Metadata];
drop procedure if exists doc.[Operation.Update];
drop type if exists doc.[OpSimpleTrans.TableType];
drop type if exists doc.[Operation.TableType];
drop type if exists doc.[OpStore.TableType];
drop type if exists doc.[OpCash.TableType];
drop type if exists doc.[OpSettle.TableType];
drop type if exists doc.[OpTrans.TableType];
drop type if exists doc.[OpMenu.TableType]
drop type if exists doc.[OpPrintForm.TableType]
drop type if exists doc.[OpLink.TableType];
go
-------------------------------------------------
create type doc.[Operation.TableType]
as table(
	Id bigint null,
	[Menu] nvarchar(32),
	[Form] nvarchar(16),
	[DocumentUrl] nvarchar(255),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Autonum bigint,
	Kind nvarchar(16)
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
create type doc.[OpPrintForm.TableType]
as table(
	Id nvarchar(16),
	Checked bit
)
go
-------------------------------------------------
create type doc.[OpLink.TableType]
as table(
	Id bigint,
	[Type] nvarchar(32),
	[Category] nvarchar(32),
	Operation bigint
)
go
-------------------------------------------------
create type doc.[OpStore.TableType]
as table(
	Id bigint,
	RowNo int,
	RowKind nvarchar(8),
	IsIn bit,
	IsOut bit,
	IsStorno bit
)
go
-------------------------------------------------
create type doc.[OpCash.TableType]
as table(
	Id bigint,
	IsIn bit,
	IsOut bit,
	IsStorno bit
)
go
-------------------------------------------------
create type doc.[OpSettle.TableType]
as table(
	Id bigint,
	IsInc bit,
	IsDec bit,
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
	DtAccKind bigint,
	DtRow nchar(1),
	DtSum nchar(1),
	CtAccMode nchar(1),
	CtAccKind bigint,
	CtRow nchar(1),
	CtSum nchar(1),
	IsStorno bit
)
go
------------------------------------------------
create or alter procedure doc.[Operation.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Operation doc.[Operation.TableType];
	declare @OpStore doc.[OpStore.TableType];
	declare @OpCash doc.[OpCash.TableType];
	declare @OpSettle doc.[OpSettle.TableType];
	declare @OpTrans doc.[OpTrans.TableType];
	declare @OpMenu doc.[OpMenu.TableType];
	declare @OpPrintForm doc.[OpPrintForm.TableType];
	declare @OpLinks doc.[OpLink.TableType];
	select [Operation!Operation!Metadata] = null, * from @Operation;
	select [Store!Operation.Store!Metadata] = null, * from @OpStore;
	select [Cash!Operation.Cash!Metadata] = null, * from @OpCash;
	select [Settle!Operation.Settle!Metadata] = null, * from @OpSettle;
	select [Trans!Operation.Trans!Metadata] = null, * from @OpTrans;
	select [Menu!Menu!Metadata] = null, * from @OpMenu;
	select [PrintForms!PrintForms!Metadata] = null, * from @OpPrintForm;
	select [Links!Operation.OpLinks!Metadata] = null, * from @OpLinks;
end
go
------------------------------------------------
create or alter procedure doc.[Operation.Update]
@TenantId bigint = 1,
@UserId bigint,
@Operation doc.[Operation.TableType] readonly,
@Store doc.[OpStore.TableType] readonly,
@Cash doc.[OpCash.TableType] readonly,
@Settle doc.[OpSettle.TableType] readonly,
@Trans doc.[OpTrans.TableType] readonly,
@Menu doc.[OpMenu.TableType] readonly,
@Links doc.[OpLink.TableType] readonly,
@PrintForms doc.[OpPrintForm.TableType] readonly
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
		t.[Form] = s.[Form],
		t.[DocumentUrl] = s.[DocumentUrl],
		t.Autonum = s.[Autonum],
		t.Kind = s.Kind
	when not matched by target then insert
		(TenantId, [Name], Form, Memo, DocumentUrl, Autonum, Kind) values
		(@TenantId, s.[Name], s.Form, s.Memo, s.DocumentUrl, s.Autonum, s.Kind)
	output inserted.Id into @rtable(id);
	select top(1) @Id = id from @rtable;

	merge doc.OpStore as t
	using @Store as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowNo = s.RowNo,
		t.RowKind = isnull(s.RowKind, N''),
		t.IsIn = s.IsIn,
		t.IsOut = s.IsOut,
		t.Factor = case when s.IsStorno = 1 then -1 else 1 end
	when not matched by target then insert
		(TenantId, Operation, RowNo, RowKind, IsIn, IsOut, Factor) values
		(@TenantId, @Id, RowNo, isnull(RowKind, N''), s.IsIn, s.IsOut, case when s.IsStorno = 1 then -1 else 1 end)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

	merge doc.OpCash as t
	using @Cash as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.IsIn = s.IsIn,
		t.IsOut = s.IsOut,
		t.Factor = case when s.IsStorno = 1 then -1 else 1 end
	when not matched by target then insert
		(TenantId, Operation, IsIn, IsOut, Factor) values
		(@TenantId, @Id, s.IsIn, s.IsOut, case when s.IsStorno = 1 then -1 else 1 end)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

	merge doc.OpSettle as t
	using @Settle as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.IsInc = s.IsInc,
		t.IsDec = s.IsDec,
		t.Factor = case when s.IsStorno = 1 then -1 else 1 end
	when not matched by target then insert
		(TenantId, Operation, IsInc, IsDec, Factor) values
		(@TenantId, @Id, s.IsInc, s.IsDec, case when s.IsStorno = 1 then -1 else 1 end)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

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
		t.DtAccKind = s.DtAccKind,
		t.CtAccMode = s.CtAccMode,
		t.CtAccKind = s.CtAccKind,
		t.DtRow = s.DtRow,
		t.CtRow = s.CtRow,
		t.DtSum = s.DtSum,
		t.CtSum = s.CtSum,
		t.Factor = case when s.IsStorno = 1 then -1 else 1 end
	when not matched by target then insert
		(TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct, DtAccMode, DtAccKind, CtAccMode, CtAccKind, 
			DtRow, CtRow, DtSum, CtSum, Factor) values
		(@TenantId, @Id, RowNo, isnull(RowKind, N''), s.[Plan], s.Dt, s.Ct, s.DtAccMode, s.DtAccKind, s.CtAccMode, s.CtAccKind, 
			s.DtRow, s.CtRow, s.DtSum, s.CtSum, case when s.IsStorno = -1 then -1 else 1 end)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	with OM as (select Id from @Menu where Checked = 1)
	merge ui.OpMenuLinks as t
	using OM as s
	on t.TenantId = @TenantId and t.Operation = @Id and t.Menu = s.Id
	when not matched by target then insert
		(TenantId, Operation, Menu) values
		(@TenantId, @Id, s.Id)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

	with OPF as (select Id from @PrintForms where Checked = 1)
	merge doc.OpPrintForms as t
	using OPF as s
	on t.TenantId = @TenantId and t.Operation = @Id and t.PrintForm = s.Id
	when not matched by target then insert
		(TenantId, Operation, PrintForm) values
		(@TenantId, @Id, s.Id)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

	merge doc.OperationLinks as t
	using @Links as s
	on t.TenantId = @TenantId and t.Id = s.Id and t.Parent = @Id
	when matched then update set
		t.[Type] = s.[Type],
		t.Category = s.[Category],
		t.Operation = s.Operation
	when not matched by target then insert
		(TenantId, Parent, Operation, [Type], [Category]) values
		(@TenantId, @Id, s.Operation, s.[Type], s.[Category])
	when not matched by source and t.TenantId = @TenantId and t.Parent = @Id then delete;

	exec doc.[Operation.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @Id;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Plain.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	if exists(select * from doc.Documents where TenantId = @TenantId and Operation = @Id) or
		exists(select * from doc.OperationLinks where TenantId = @TenantId and Operation = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	begin tran;
	delete from doc.OpTrans where TenantId = @TenantId and Operation = @Id;
	delete from ui.OpMenuLinks where TenantId = @TenantId and Operation = @Id;
	delete from doc.OperationLinks where TenantId = @TenantId and Parent = @Id;
	delete from doc.Operations where TenantId = @TenantId and Id = @Id;
	commit tran;

end
go

/* Document.Common */
------------------------------------------------
create or alter procedure doc.[Document.MainMaps] 
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [!TRespCenter!Map] = null, [Id!!Id] = rc.Id, [Name!!Name] = rc.[Name]
	from cat.RespCenters rc inner join doc.Documents d on d.TenantId = rc.TenantId and d.RespCenter = rc.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [!TProject!Map] = null, [Id!!Id] = p.Id, [Name!!Name] = p.[Name]
	from cat.Projects p inner join doc.Documents d on d.TenantId = p.TenantId and d.Project = p.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [!TContract!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Date], c.[SNo],
		[PriceKind!TPriceKind!RefId] = c.PriceKind, [Company!TCompany!RefId] = c.Company, 
		[Agent!TAgent!RefId] = c.Agent
	from doc.Contracts c inner join doc.Documents d on d.TenantId = c.TenantId and d.[Contract] = c.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	with TA as (
		select Agent from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id
		union all
		select c.Agent from doc.Documents d inner join doc.Contracts c on c.TenantId = d.TenantId and c.Id = d.[Contract]
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a
	where a.TenantId = @TenantId and a.Id in (select Agent from TA);

	with CA as(
		select Company from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id
		union all
		select c.Company from doc.Documents d inner join doc.Contracts c on c.TenantId = d.TenantId and c.Id = d.[Contract]
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
	where c.TenantId = @TenantId and c.Id in (select Company from CA);

end
go
------------------------------------------------
create or alter procedure doc.[Document.LinkedMaps] 
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done], d.BindKind, d.BindFactor,
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Parent
	from doc.Documents d 
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Parent = @Id;

	select [!TDocBase!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], p.[Done], p.BindKind, p.BindFactor,
		[OpName] = o.[Name], o.Form, o.DocumentUrl
	from doc.Documents p inner join doc.Documents d on d.TenantId = p.TenantId and p.Id in (d.Parent, d.Base)
		inner join doc.Operations o on p.TenantId = o.TenantId and p.Operation = o.Id
	where d.Id = @Id and d.TenantId = @TenantId;
end
go
------------------------------------------------
create or alter procedure doc.[Document.DeleteTemp]
@TenantId int =1,
@UserId bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @docs table(id bigint);	
	insert into @docs(id) 
	select Id from doc.Documents where TenantId = @TenantId and UserCreated = @UserId and Temp = 1;

	delete from doc.DocDetails from
		doc.DocDetails dd inner join @docs d on dd.TenantId = @TenantId and dd.Document = d.id
	update doc.Documents set Base = null, BindKind = null, BindFactor = null 
	where TenantId = @TenantId and Base in (select id from @docs);
	update doc.Documents set Parent = null where TenantId = @TenantId and Parent in (select id from @docs);

	delete from doc.Documents where Id in (select id from @docs);
end
go
-------------------------------------------------
create or alter procedure doc.[Document.Rems.Get]
@TenantId int = 1,
@UserId bigint,
@Items nvarchar(max),
@Date date,
@CheckRems bit = 1,
@Wh bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @itemstable a2sys.[Id.TableType];
	insert into @itemstable (Id) 
		select [value] from string_split(@Items, N',');

	select [Rems!TRem!Array] = null, r.Item, r.Rem, r.[Role]
	from doc.fn_getItemsRems(@CheckRems, @TenantId, @itemstable, @Date, @Wh) r;
end
go
------------------------------------------------
create or alter procedure doc.[Autonum.NextValue]
@TenantId int, 
@Company bigint, 
@Autonum bigint, 
@Date date, 
@Number nvarchar(64) output
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if 0 = isnull(@Autonum, 0) or @Company is null
	begin
		set @Number = null;
		return;
	end
		

	declare @m int, @q int, @y int, @pattern nvarchar(255);
	declare @compprefix nvarchar(8);
	
	select @compprefix = isnull(AutonumPrefix, N'') from cat.Companies 
		where TenantId = @TenantId and Id=@Company;
	select @pattern = Pattern,
		@m = case when [Period] = N'M'  then month(@Date) else 0 end,
		@q = case when [Period] = N'Q'  then datepart(quarter, @Date) else 0 end,
		@y = case when [Period] <> N'A' then year(@Date) else 0 end
	from doc.Autonums where TenantId = @TenantId and Id = @Autonum;

	declare @rtable table(number int);
	begin tran;
		update doc.AutonumValues set CurrentNumber = CurrentNumber + 1 
			output inserted.CurrentNumber into @rtable(number)
		where TenantId = @TenantId and Company = @Company and Autonum = @Autonum 
			and [Year] = @y and Quart = @q and [Month] = @m;
	if @@rowcount = 0
		insert into doc.AutonumValues(TenantId, Company, Autonum, [Year], [Quart], [Month], CurrentNumber)
			output inserted.CurrentNumber into @rtable(number)
		values(@TenantId, @Company, @Autonum, @y, @q, @m, 1);
	commit tran;
	
	-- and format number
	declare @n int;
	select @n = number from @rtable;
	--select format(@n, replicate(N'0', 5));
	set @Number = replace(@pattern, N'{yy}', format(@Date, N'yy'));
	set @Number = replace(@Number, N'{yyyy}', format(@Date, N'yyyy'));
	set @Number = replace(@Number, N'{mm}', format(@Date, N'MM'));
	set @Number = replace(@Number, N'{qq}', format(datepart(quarter, @Date), N'00'));
	set @Number = replace(@Number, N'{p}', @compprefix);
	declare @p0 int, @p1 int, @patno nvarchar(255);
	set @p0 = charindex(N'{n', @Number);
	set @p1 = charindex(N'n}', @Number);
	if @p0 > 0 and @p1 > 0
		set @patno = replicate(N'0', @p1 - @p0);
	else
		set @patno = N'0';
	set @Number = stuff(@Number, @p0, @p1 - @p0 + 2, format(@n, @patno));
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

	exec doc.[Document.DeleteTemp] @TenantId = @TenantId, @UserId = @UserId;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date;
	set @end = dateadd(day, 1, @To);

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @docs table(rowno int identity(1, 1), id bigint, op bigint, agent bigint, 
		comp bigint, whfrom bigint, whto bigint, base bigint, rowcnt int);

	insert into @docs(id, op, agent, comp, whfrom, whto, base, rowcnt)
	select d.Id, d.Operation, d.Agent, d.Company, d.WhFrom, d.WhTo, d.Base,
		count(*) over()
	from doc.Documents d
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and d.Operation = ml.Operation
	where d.TenantId = @TenantId and d.Temp = 0 and ml.Menu = @Menu
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
		case when @Dir = N'asc' then
			case @Order 
				when N'no' then isnull(d.[SNo], d.[No])
				when N'memo' then d.[Memo]
			end
		end asc,
		-- desc
		case when @Dir = N'desc' then
			case @Order
				when N'date' then d.[Date]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'sum' then d.[Sum]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order 
				when N'no' then isnull(d.[SNo], d.[No])
				when N'memo' then d.[Memo]
			end
		end desc,
		Id desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.SNo, d.[No],
		d.Notice, d.Done, d.BindKind, d.BindFactor, [BaseDoc!TDocBase!RefId] = d.Base,
		[Operation!TOperation!RefId] = d.Operation,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[WhFrom!TWarehouse!RefId] = d.WhFrom, [WhTo!TWarehouse!RefId] = d.WhTo,
		[!!RowCount] = t.rowcnt
	from @docs t inner join 
		doc.Documents d on d.TenantId = @TenantId and d.Id = t.id
	order by t.rowno;

	-- maps
	with T as (select op from @docs group by op)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
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

	with T as (select base from @docs group by base)
	select [!TDocBase!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], p.[Done], p.[No], p.BindKind, p.BindFactor,
		[OpName] = o.[Name], o.Form, o.DocumentUrl
	from doc.Documents p inner join T on p.TenantId = @TenantId and p.Id = T.base
		inner join doc.Operations o on p.TenantId = o.TenantId and p.Operation = o.Id;

	-- menu
	select [Menu!TMenu!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], FormId = f.Id, FormName = f.[Name],
		o.[DocumentUrl]
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by f.[Order];

	select [Operations!TOperation!Array] = null, [Id!!Id] = -1, [Name!!Name] = N'@[Filter.AllOperations]', null, null, [!Order] = -1
	union all
	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form], o.DocumentUrl, [!Order] = o.Id
	from doc.Operations o
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by [!Order];

	-- filters
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
@Operation bigint = null,
@CheckRems bit = 0
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docform nvarchar(16);
	declare @done bit;
	if @Operation is null
		select @Operation = d.Operation from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id;

	if @Id <> 0 and 1 = (select Done from doc.Documents where TenantId =@TenantId and Id = @Id)
		set @CheckRems = 0;
	set @CheckRems = app.fn_IsCheckRems(@TenantId, @CheckRems);

	select @docform = o.Form from doc.Operations o where o.TenantId = @TenantId and o.Id = @Operation;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.SNo, d.[No], d.Notice, d.[Sum], d.Done, d.BindKind, d.BindFactor,
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, [WhFrom!TWarehouse!RefId] = d.WhFrom,
		[WhTo!TWarehouse!RefId] = d.WhTo, [Contract!TContract!RefId] = d.[Contract], 
		[PriceKind!TPriceKind!RefId] = d.PriceKind, [RespCenter!TRespCenter!RefId] = d.RespCenter,
		[CostItem!TCostItem!RefId] = d.CostItem, [ItemRole!TItemRole!RefId] = d.ItemRole, [Project!TProject!RefId] = d.Project,
		[StockRows!TRow!Array] = null,
		[ServiceRows!TRow!Array] = null,
		[ParentDoc!TDocBase!RefId] = d.Parent, [BaseDoc!TDocBase!RefId] = d.Base,
		[LinkedDocs!TDocBase!Array] = null,
		[Extra!TDocExtra!Object] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	declare @rows table(id bigint, item bigint, unit bigint, [role] bigint, costitem bigint);
	insert into @rows (id, item, unit, [role], costitem)
	select Id, Item, Unit, ItemRole, CostItem from doc.DocDetails dd
	where dd.TenantId = @TenantId and dd.Document = @Id;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], FQty, Price, [Sum], ESum, DSum, TSum,
		[Item!TItem!RefId] = dd.Item, [Unit!TUnit!RefId] = Unit, 
		[ItemRole!TItemRole!RefId] = dd.ItemRole, [ItemRoleTo!TItemRole!RefId] = dd.ItemRoleTo,
		[CostItem!TCostItem!RefId] = dd.CostItem,
		[!TDocument.StockRows!ParentId] = dd.Document, [RowNo!!RowNumber] = RowNo,
		Rem = r.[Rem]
	from doc.DocDetails dd
		left join doc.fn_getDocumentRems(@CheckRems, @TenantId, @Id) r on dd.Item = r.Item and dd.ItemRole = r.[Role]
	where dd.TenantId=@TenantId and dd.Document = @Id and dd.Kind = N'Stock'
	order by RowNo;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], FQty, Price, [Sum], ESum, DSum, TSum, 
		[Item!TItem!RefId] = Item, [Unit!TUnit!RefId] = Unit, [ItemRole!TItemRole!RefId] = dd.ItemRole,
		[CostItem!TCostItem!RefId] = dd.CostItem,
		[!TDocument.ServiceRows!ParentId] = dd.Document, [RowNo!!RowNumber] = RowNo
	from doc.DocDetails dd
	where dd.TenantId=@TenantId and dd.Document = @Id and dd.Kind = N'Service'
	order by RowNo;

	select [!TDocExtra!Object] = null, [Id!!Id] = da.Id, da.[WriteSupplierPrices], da.[IncludeServiceInCost],
		[!TDocument.Extra!ParentId] = da.Id
	from doc.DocumentExtra da where da.TenantId = @TenantId and da.Id = @Id;

	-- maps
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl,
		[Links!TOpLink!Array] = null
	from doc.Operations o 
	where o.TenantId = @TenantId and o.Id = @Operation;

	select [!TOpLink!Array] = null, [Id!!Id] = ol.Id, ol.Category, ch.[Name], [!TOperation.Links!ParentId] = ol.Parent
	from doc.OperationLinks ol 
		inner join doc.Operations ch on ol.TenantId = ch.TenantId and ol.Operation = ch.Id
	where ol.TenantId = @TenantId and ol.Parent = @Operation;

	select [!TWarehouse!Map] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name]
	from cat.Warehouses w inner join doc.Documents d on d.TenantId = w.TenantId and w.Id in (d.WhFrom, d.WhTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by w.Id, w.[Name];

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind,
		[CostItem!TCostItem!RefId] = ir.CostItem
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0;

	with T as (
		select CostItem from doc.Documents d where TenantId = @TenantId and d.Id = @Id
		union all 
		select costitem from @rows dd group by costitem
		union all
		select ir.CostItem from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0
		group by ir.CostItem
	)
	select [!TCostItem!Map] = null, [Id!!Id] = ci.Id, [Name!!Name] = ci.[Name]
	from cat.CostItems ci 
	where ci.TenantId = @TenantId and ci.Id in (select CostItem from T);

	with T as (select PriceKind from doc.Documents d where TenantId = @TenantId and d.Id = @Id
		union all 
		select c.PriceKind from doc.Documents d inner join doc.Contracts c on d.TenantId = @TenantId and d.[Contract] = c.Id
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk 
	where pk.TenantId = @TenantId and pk.Id in (select PriceKind from T);

	exec doc.[Document.MainMaps] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;
	exec doc.[Document.LinkedMaps]  @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

	with T as (select item from @rows group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], Article, Barcode,
		Price = cast(null as float), Rem = cast(null as float),
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit!] = u.Short, 
		[Role.Id!TItemRole!RefId] = i.[Role],
		[CostItem.Id!TCostItem!Id] = ir.[CostItem], [CostItem.Name!TCostItem!Name] = ci.[Name]
	from cat.Items i inner join T on i.Id = T.item and i.TenantId = @TenantId
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
		left join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
		left join cat.CostItems ci on i.TenantId = ci.TenantId and ir.CostItem = ci.Id
	where i.TenantId = @TenantId;

	with T as (select unit from @rows group by unit)
	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.Short
	from cat.Units u inner join T on u.Id = T.unit and u.TenantId = @TenantId
	where u.TenantId = @TenantId;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form]
	from doc.Operations o where TenantId = @TenantId and Form=@docform
	order by Id;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [Params!TParam!Object] = null, [Operation] = @Operation, CheckRems = @CheckRems;

	select [!$System!] = null, [!!ReadOnly] = d.Done
	from doc.Documents d where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
drop procedure if exists doc.[Document.Stock.UpdateBase];
drop procedure if exists doc.[Document.Stock.Metadata];
drop procedure if exists doc.[Document.Stock.Update];
drop procedure if exists doc.[Document.Order.Metadata];
drop procedure if exists doc.[Document.Order.Update];
drop procedure if exists doc.[Document.Rows.Merge];
drop type if exists cat.[Document.Stock.TableType];
drop type if exists cat.[Document.Stock.Row.TableType];
drop type if exists cat.[Document.Extra.TableType];
go
------------------------------------------------
create type cat.[Document.Stock.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Sum] money,
	[SNo] nvarchar(64),
	[No] nvarchar(64),
	Operation bigint,
	Agent bigint,
	Company bigint,
	WhFrom bigint,
	WhTo bigint,
	[Contract] bigint,
	PriceKind bigint,
	RespCenter bigint,
	Project bigint,
	CostItem bigint,
	ItemRole bigint,
	Memo nvarchar(255),
	[State] bigint
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
	ItemRole bigint,
	ItemRoleTo bigint,
	[Qty] float,
	[FQty] float,
	[Price] money,
	[Sum] money,
	ESum money,
	DSum money,
	TSum money,
	Memo nvarchar(255),
	CostItem bigint
)
go
------------------------------------------------
create type cat.[Document.Extra.TableType]
as table(
	ParentId bigint,
	WriteSupplierPrices bit,
	IncludeServiceInCost bit
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
	declare @Extra cat.[Document.Extra.TableType];

	select [Document!Document!Metadata] = null, * from @Document;
	select [Extra!Document.Extra!Metadata] = null, * from @Extra;
	select [StockRows!Document.StockRows!Metadata] = null, * from @Rows;
	select [ServiceRows!Document.ServiceRows!Metadata] = null, * from @Rows;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Rows.Merge]
@TenantId int = 1,
@Id bigint,
@Kind nvarchar(16),
@Rows cat.[Document.Stock.Row.TableType] readonly
as
begin
	with DD as (select * from doc.DocDetails where TenantId = @TenantId and Document = @Id and Kind=@Kind)
	merge DD as t
	using @Rows as s on t.Id = s.Id
	when matched then update set
		t.RowNo = s.RowNo,
		t.Item = s.Item,
		t.Unit = s.Unit,
		t.ItemRole = nullif(s.ItemRole, 0),
		t.ItemRoleTo = nullif(s.ItemRoleTo, 0),
		t.Qty = s.Qty,
		t.FQty = s.FQty,
		t.Price = s.Price,
		t.[Sum] = s.[Sum],
		t.ESum = s.ESum,
		t.DSum = s.DSum,
		t.TSum = s.TSum,
		t.CostItem = s.CostItem
	when not matched by target then insert
		(TenantId, Document, Kind, RowNo, Item, Unit, ItemRole, ItemRoleTo, Qty, FQty, Price, [Sum], ESum, DSum, TSum, 
			CostItem) values
		(@TenantId, @Id, @Kind, s.RowNo, s.Item, s.Unit, nullif(s.ItemRole, 0), nullif(s.ItemRoleTo, 0), s.Qty, s.FQty, s.Price, s.[Sum], s.ESum, s.DSum, s.TSum, 
			s.CostItem)
	when not matched by source and t.TenantId = @TenantId and t.Document = @Id and t.Kind=@Kind then delete;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.UpdateBase]
@TenantId int = 1,
@UserId bigint,
@Document cat.[Document.Stock.TableType] readonly,
@Extra cat.[Document.Extra.TableType] readonly,
@StockRows cat.[Document.Stock.Row.TableType] readonly,
@ServiceRows cat.[Document.Stock.Row.TableType] readonly,
@RetId bigint output
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Apply for xml auto);
	throw 60000, @xml, 0;
	*/

	declare @rtable table(id bigint);
	declare @id bigint;

	declare @no nvarchar(64);
	select @no = [No] from @Document;
	if @no is null
	begin
		declare @autonumAN bigint, @autonumComp bigint, @autonumDate date;

		select @autonumAN = o.Autonum, @autonumComp = d.Company, @autonumDate = d.[Date]
		from @Document d inner join doc.Operations o on d.Operation = o.Id and o.TenantId = @TenantId;

		exec doc.[Autonum.NextValue] 
			@TenantId = @TenantId, @Company = @autonumComp, @Autonum = @autonumAN, @Date = @autonumDate, @Number = @no output;
	end

	merge doc.Documents as t
	using @Document as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.Temp = 0,
		t.Operation = s.Operation,
		t.[Date] = s.[Date],
		t.[Sum] = s.[Sum],
		t.Company = s.Company,
		t.Agent = s.Agent,
		t.WhFrom = s.WhFrom,
		t.WhTo = s.WhTo,
		t.[Contract] = s.[Contract],
		t.PriceKind = s.PriceKind,
		t.RespCenter = s.RespCenter,
		t.Project = s.Project,
		t.CostItem = s.CostItem,
		t.ItemRole = s.ItemRole,
		t.Memo = s.Memo,
		t.SNo = s.SNo,
		t.[No] = @no,
		t.[State] = s.[State]
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, WhFrom, WhTo, [Contract], 
			PriceKind, RespCenter, Project, CostItem, ItemRole, Memo, SNo, [No], [State], UserCreated) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, WhFrom, s.WhTo, s.[Contract], 
			s.PriceKind, s.RespCenter, s.Project, s.CostItem, s.ItemRole, s.Memo, s.SNo, @no, s.[State], @UserId)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	merge doc.DocumentExtra as t
	using @Extra as s
	on t.TenantId = @TenantId and t.Id = @id
	when matched then update set
		t.WriteSupplierPrices = s.WriteSupplierPrices,
		t.IncludeServiceInCost = s.IncludeServiceInCost
	when not matched then insert
		(TenantId, Id, WriteSupplierPrices, IncludeServiceInCost) values
		(@TenantId, @id, s.WriteSupplierPrices, s.IncludeServiceInCost);

	exec doc.[Document.Rows.Merge] @TenantId = @TenantId, @Id = @id, @Kind = N'Stock', @Rows = @StockRows;
	exec doc.[Document.Rows.Merge] @TenantId = @TenantId, @Id = @id, @Kind = N'Service', @Rows = @ServiceRows;

	set @RetId = @id;
end
go

------------------------------------------------
create or alter procedure doc.[Document.Stock.Update]
@TenantId int = 1,
@UserId bigint,
@Document cat.[Document.Stock.TableType] readonly,
@Extra cat.[Document.Extra.TableType] readonly,
@StockRows cat.[Document.Stock.Row.TableType] readonly,
@ServiceRows cat.[Document.Stock.Row.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	declare @id bigint;
	exec doc.[Document.Stock.UpdateBase] @TenantId = @TenantId, @UserId = @UserId,
		@Document = @Document, @Extra = @Extra,
		@StockRows = @StockRows, @ServiceRows = @ServiceRows, @RetId = @id output;
	exec doc.[Document.Stock.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
/* Document.Pay */
------------------------------------------------
create or alter procedure doc.[Document.Pay.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(255),
@AccMode nvarchar(16) = N'All',
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

	exec doc.[Document.DeleteTemp] @TenantId = @TenantId, @UserId = @UserId;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date;
	set @end = dateadd(day, 1, @To);

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @docs table(rowno int identity(1, 1), id bigint, op bigint, agent bigint, 
		comp bigint, bafrom bigint, bato bigint, cafrom bigint, cato bigint, base bigint, rowcnt int);

	insert into @docs(id, op, agent, comp, cafrom, cato, base, rowcnt)
	select d.Id, d.Operation, d.Agent, d.Company, d.CashAccFrom, d.CashAccTo, d.Base,
		count(*) over()
	from doc.Documents d
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and d.Operation = ml.Operation
	where d.TenantId = @TenantId and d.Temp = 0 and ml.Menu = @Menu
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
		case when @Dir = N'desc' then
			case @Order
				when N'date' then d.[Date]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order 
				when N'sum' then d.[Sum]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'sum' then d.[Sum]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order 
				when N'id' then d.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then d.[Id]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order 
				when N'no' then isnull(d.[No], d.SNo)
				when N'memo' then d.Memo
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'no' then isnull(d.[No], d.SNo)
				when N'memo' then d.Memo
			end
		end desc,
		d.Id desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.[Notice], d.SNo, d.[No], d.Done, d.BindKind, d.BindFactor,
		[Operation!TOperation!RefId] = d.Operation, [BaseDoc!TDocBase!RefId] = d.Base,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[CashAccFrom!TCashAccount!RefId] = d.CashAccFrom, [CashAccTo!TCashAccount!RefId] = d.CashAccTo,
		[!!RowCount] = t.rowcnt
	from @docs t inner join 
		doc.Documents d on d.TenantId = @TenantId and d.Id = t.id
	order by t.rowno;

	-- maps
	with T as (select op from @docs group by op)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o 
		inner join T t on o.TenantId = @TenantId and o.Id = op;

	with T as (select agent from @docs group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with C as (select ca = cafrom from @docs union all select cato from @docs),
	T as (select ca from C group by ca)
	select [!TCashAccount!Map] = null, [Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.[AccountNo],
		Balance = cast(0 as money)
	from cat.CashAccounts ca
		inner join T t on ca.TenantId = @TenantId and ca.Id = ca;

	with T as (select comp from @docs group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	with T as (select base from @docs group by base)
	select [!TDocBase!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], p.[Done], p.[No], p.BindKind, p.BindFactor,
		[OpName] = o.[Name], o.Form, o.DocumentUrl
	from doc.Documents p inner join T on p.TenantId = @TenantId and p.Id = T.base
		inner join doc.Operations o on p.TenantId = o.TenantId and p.Operation = o.Id;

	-- menu
	select [Menu!TMenu!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], FormId = f.Id, FormName = f.[Name],
		o.DocumentUrl
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by f.[Order];

	-- params
	select [Params!TParam!Object] = null, [Menu] = @Menu, AccMode = @AccMode;

	-- filters
	select [Operations!TOperation!Array] = null, [Id!!Id] = -1, [Name!!Name] = N'@[Filter.AllOperations]', null, null, [!Order] = -1
	union all
	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form], o.DocumentUrl, [!Order] = o.Id
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

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.Notice, d.SNo, d.[No], d.[Sum], d.Done, d.BindKind, d.BindFactor,
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, 
		[CashAccFrom!TCashAccount!RefId] = d.CashAccFrom, [CashAccTo!TCashAccount!RefId] = d.CashAccTo,
		[Contract!TContract!RefId] = d.[Contract], [CashFlowItem!TCashFlowItem!RefId] = d.CashFlowItem,
		[RespCenter!TRespCenter!RefId] = d.RespCenter, [ItemRole!TItemRole!RefId] = d.ItemRole, [Project!TProject!RefId] = d.Project,
		[ParentDoc!TDocBase!RefId] = d.Parent, [BaseDoc!TDocBase!RefId] = d.Base,
		[LinkedDocs!TDocBase!LazyArray] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl,
		[Links!TOpLink!Array] = null
	from doc.Operations o 
	where o.TenantId = @TenantId and o.Id = @Operation;

	select [!TOpLink!Array] = null, [Id!!Id] = ol.Id, ol.Category, ch.[Name], [!TOperation.Links!ParentId] = ol.Parent
	from doc.OperationLinks ol 
		inner join doc.Operations ch on ol.TenantId = ch.TenantId and ol.Operation = ch.Id
	where ol.TenantId = @TenantId and ol.Parent = @Operation;

	select [!TCashAccount!Map] = null, [Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.AccountNo,
		Balance = rep.fn_getCashAccountRem(@TenantId, ca.Id, d.[Date])
	from cat.CashAccounts ca inner join doc.Documents d on d.TenantId = ca.TenantId and ca.Id in (d.CashAccFrom, d.CashAccTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by ca.Id, ca.[Name], ca.AccountNo, d.[Date];

	select [!TCashFlowItem!Map] = null, [Id!!Id] = cf.Id, [Name!!Name] = cf.[Name]
	from cat.CashFlowItems cf inner join doc.Documents d on d.TenantId = cf.TenantId and cf.Id = d.CashFlowItem
	where d.Id = @Id and d.TenantId = @TenantId
	group by cf.Id, cf.[Name];


	exec doc.[Document.MainMaps] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;
	exec doc.[Document.LinkedMaps]  @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

	select [!TDocParent!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], [OperationName] = o.[Name]
	from doc.Documents p inner join doc.Documents d on d.TenantId = p.TenantId and d.Parent = p.Id
	inner join doc.Operations o on p.TenantId = o.TenantId and p.Operation = o.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form], DocumentUrl
	from doc.Operations where TenantId = @TenantId and Form=@docform
	order by Id;

	select [!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind,
		[CostItem!TCostItem!RefId] = ir.CostItem
	from cat.ItemRoles ir inner join doc.Documents d on ir.TenantId = d.TenantId and d.ItemRole = ir.Id
	where ir.TenantId = @TenantId and ir.Void = 0 and d.Id = @Id;

	select [Params!TParam!Object] = null, [Operation] = @Operation;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [!$System!] = null, [!!ReadOnly] = d.Done
	from doc.Documents d where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
drop procedure if exists doc.[Document.Pay.Metadata];
drop procedure if exists doc.[Document.Pay.Update];
drop type if exists doc.[Document.Pay.TableType];
go
------------------------------------------------
create type doc.[Document.Pay.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Sum] money,
	Operation bigint,
	Agent bigint,
	Company bigint,
	CashAccFrom bigint,
	CashAccTo bigint,
	[Contract] bigint,
	[CashFlowItem] bigint,
	RespCenter bigint,
	Memo nvarchar(255),
	Notice nvarchar(255),
	SNo nvarchar(64),
	[No] nvarchar(64),
	ItemRole bigint,
	Project bigint
)
go
------------------------------------------------
create or alter procedure doc.[Document.Pay.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Document doc.[Document.Pay.TableType];
	select [Document!Document!Metadata] = null, * from @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Pay.Update]
@TenantId int = 1,
@UserId bigint,
@Document doc.[Document.Pay.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;


	declare @no nvarchar(64);
	select @no = [No] from @Document;
	if @no is null
	begin
		declare @autonumAN bigint, @autonumComp bigint, @autonumDate date;

		select @autonumAN = o.Autonum, @autonumComp = d.Company, @autonumDate = d.[Date]
		from @Document d inner join doc.Operations o on d.Operation = o.Id and o.TenantId = @TenantId;

		exec doc.[Autonum.NextValue] 
			@TenantId = @TenantId, @Company = @autonumComp, @Autonum = @autonumAN, @Date = @autonumDate, @Number = @no output;
	end

	merge doc.Documents as t
	using @Document as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.Temp = 0,
		t.Operation = s.Operation,
		t.[Date] = s.[Date],
		t.[Sum] = s.[Sum],
		t.Company = s.Company,
		t.Agent = s.Agent,
		t.CashAccFrom = s.CashAccFrom,
		t.CashAccTo = s.CashAccTo,
		t.[Contract] = s.[Contract],
		t.CashFlowItem = s.CashFlowItem,
		t.RespCenter = s.RespCenter,
		t.Project = s.Project,
		t.Memo = s.Memo,
		t.Notice = s.Notice,
		t.[No] = @no,
		t.[SNo] = s.SNo,
		t.ItemRole = s.ItemRole
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, 
			CashAccFrom, CashAccTo, [Contract], CashFlowItem, RespCenter, Project, Memo, Notice, SNo, [No], ItemRole, UserCreated) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, 
			s.CashAccFrom, s.CashAccTo, s.[Contract], s.CashFlowItem, s.RespCenter, s.Project, s.Memo, s.Notice, s.SNo, @no, s.ItemRole, @UserId)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	exec doc.[Document.Pay.Load] @TenantId = @TenantId, 
	@UserId = @UserId, @Id = @id;
end
go


/* Document.Order */
------------------------------------------------
create or alter procedure doc.[Document.Order.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(255),
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'desc',
@Operation bigint = -1,
@Agent bigint = null,
@Company bigint = null,
@From date = null,
@To date = null,
@State nvarchar(1) = N'W'
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec doc.[Document.DeleteTemp] @TenantId = @TenantId, @UserId = @UserId;

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
		left join doc.DocStates ds on d.TenantId = ds.TenantId and d.[State] = ds.Id
	where d.TenantId = @TenantId and d.Temp = 0 and ml.Menu = @Menu
		and (d.[Date] >= @From and d.[Date] < @end)
		and (@Operation = -1 or d.Operation = @Operation)
		and (@Agent is null or d.Agent = @Agent)
		and (@Company is null or d.Company = @Company)
		and (@State = N'A' or @State = N'W' and ds.Kind in (N'I', N'P') or @State = ds.Kind)
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
		case when @Dir = N'asc' then
			case @Order 
				when N'no' then isnull(d.[SNo], d.[No])
				when N'memo' then d.[Memo]
			end
		end asc,
		-- desc
		case when @Dir = N'desc' then
			case @Order
				when N'date' then d.[Date]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'sum' then d.[Sum]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order 
				when N'no' then isnull(d.[SNo], d.[No])
				when N'memo' then d.[Memo]
			end
		end desc,
		Id desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.SNo, d.[No],
		d.Notice, d.Done, d.BindKind, d.BindFactor,
		[Operation!TOperation!RefId] = d.Operation, 
		[State.Id!TState!Id] = d.[State], [State.Name!TState!Name] = ds.[Name], [State.Color!TState!] = ds.Color,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[WhFrom!TWarehouse!RefId] = d.WhFrom, [WhTo!TWarehouse!RefId] = d.WhTo,
		[LinkedDocs!TDocBase!Array] = null,
		[!!RowCount] = t.rowcnt
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and d.Id = t.id
		left join doc.DocStates ds on d.TenantId = ds.TenantId and d.[State] = ds.Id
	order by t.rowno;

	-- arrays
	-- from BASE!!!
	select [!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done], d.BindKind, d.BindFactor,
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Base
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and t.id = d.Base
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Base = t.id;

	/*
	-- payments/shipment
	select [!TBind!Object] = null, [!TDocument.Bind!ParentId] = [Base], [Payment], [Shipment] 
	from (
		select [Base], Kind = r.BindKind, [Sum] = [Sum] * r.BindFactor
		from doc.Documents r 
		inner join @docs t on r.TenantId = @TenantId and r.Base = t.id
	) 
	as s pivot (  
		sum([Sum])  
		for Kind in ([Payment], [Shipment])  
	) as p;  
	*/

	-- maps
	with T as (select op from @docs group by op)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
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
	select [Menu!TMenu!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], FormId = f.Id, FormName = f.[Name],
		o.[DocumentUrl]
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
		inner join ui.OpMenuLinks ml on o.TenantId = ml.TenantId and o.Id = ml.Operation
	where o.TenantId = @TenantId and ml.Menu = @Menu
	order by f.[Order];

	-- filters
	select [Operations!TOperation!Array] = null, [Id!!Id] = -1, [Name!!Name] = N'@[Filter.AllOperations]', null, null, [!Order] = -1
	union all
	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form], o.DocumentUrl, [!Order] = o.Id
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
		[!Documents.State!Filter] = @State
end
go
------------------------------------------------
create or alter procedure doc.[Document.Order.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Operation bigint = null,
@CheckRems bit = 0
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docform nvarchar(16);
	declare @done bit;
	if @Operation is null
		select @Operation = d.Operation from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id;

	if @Id <> 0 and 1 = (select Done from doc.Documents where TenantId =@TenantId and Id = @Id)
		set @CheckRems = 0;
	set @CheckRems = app.fn_IsCheckRems(@TenantId, @CheckRems);

	select @docform = o.Form from doc.Operations o where o.TenantId = @TenantId and o.Id = @Operation;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.SNo, d.[No], d.Notice, d.[Sum], d.Done, d.BindKind, d.BindFactor, 
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, [WhFrom!TWarehouse!RefId] = d.WhFrom,
		[WhTo!TWarehouse!RefId] = d.WhTo, [Contract!TContract!RefId] = d.[Contract], 
		[PriceKind!TPriceKind!RefId] = d.PriceKind, [RespCenter!TRespCenter!RefId] = d.RespCenter,
		[CostItem!TCostItem!RefId] = d.CostItem, [ItemRole!TItemRole!RefId] = d.ItemRole, [Project!TProject!RefId] = d.Project,
		[State!TState!RefId] = d.[State], 
		[StockRows!TRow!Array] = null,
		[ServiceRows!TRow!Array] = null,
		[LinkedDocs!TDocBase!Array] = null,
		[Extra!TDocExtra!Object] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	declare @rows table(id bigint, item bigint, unit bigint, [role] bigint, costitem bigint);
	insert into @rows (id, item, unit, [role], costitem)
	select Id, Item, Unit, ItemRole, CostItem from doc.DocDetails dd
	where dd.TenantId = @TenantId and dd.Document = @Id;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], FQty, Price, [Sum], ESum, DSum, TSum,
		[Item!TItem!RefId] = dd.Item, [Unit!TUnit!RefId] = Unit, 
		[ItemRole!TItemRole!RefId] = dd.ItemRole, [ItemRoleTo!TItemRole!RefId] = dd.ItemRoleTo,
		[CostItem!TCostItem!RefId] = dd.CostItem,
		[!TDocument.StockRows!ParentId] = dd.Document, [RowNo!!RowNumber] = RowNo,
		Rem = r.[Rem]
	from doc.DocDetails dd
		left join doc.fn_getDocumentRems(@CheckRems, @TenantId, @Id) r on dd.Item = r.Item and dd.ItemRole = r.[Role]
	where dd.TenantId=@TenantId and dd.Document = @Id and dd.Kind = N'Stock'
	order by RowNo;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], FQty, Price, [Sum], ESum, DSum, TSum, 
		[Item!TItem!RefId] = Item, [Unit!TUnit!RefId] = Unit, [ItemRole!TItemRole!RefId] = dd.ItemRole,
		[CostItem!TCostItem!RefId] = dd.CostItem,
		[!TDocument.ServiceRows!ParentId] = dd.Document, [RowNo!!RowNumber] = RowNo
	from doc.DocDetails dd
	where dd.TenantId=@TenantId and dd.Document = @Id and dd.Kind = N'Service'
	order by RowNo;

	select [!TDocExtra!Object] = null, [Id!!Id] = da.Id, da.[WriteSupplierPrices], da.[IncludeServiceInCost],
		[!TDocument.Extra!ParentId] = da.Id
	from doc.DocumentExtra da where da.TenantId = @TenantId and da.Id = @Id;

	-- maps
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl,
		[Links!TOpLink!Array] = null
	from doc.Operations o 
	where o.TenantId = @TenantId and o.Id = @Operation;

	select [!TOpLink!Array] = null, [Id!!Id] = ol.Id, ol.Category, ch.[Name], [!TOperation.Links!ParentId] = ol.Parent
	from doc.OperationLinks ol 
		inner join doc.Operations ch on ol.TenantId = ch.TenantId and ol.Operation = ch.Id
	where ol.TenantId = @TenantId and ol.Parent = @Operation;

	select [!TWarehouse!Map] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name]
	from cat.Warehouses w inner join doc.Documents d on d.TenantId = w.TenantId and w.Id in (d.WhFrom, d.WhTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by w.Id, w.[Name];

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind,
		[CostItem!TCostItem!RefId] = ir.CostItem
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0;

	with T as (
		select CostItem from doc.Documents d where TenantId = @TenantId and d.Id = @Id
		union all 
		select costitem from @rows dd group by costitem
		union all
		select ir.CostItem from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0
		group by ir.CostItem
	)
	select [!TCostItem!Map] = null, [Id!!Id] = ci.Id, [Name!!Name] = ci.[Name]
	from cat.CostItems ci 
	where ci.TenantId = @TenantId and ci.Id in (select CostItem from T);

	with T as (select PriceKind from doc.Documents d where TenantId = @TenantId and d.Id = @Id
		union all 
		select c.PriceKind from doc.Documents d inner join doc.Contracts c on d.TenantId = @TenantId and d.[Contract] = c.Id
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk 
	where pk.TenantId = @TenantId and pk.Id in (select PriceKind from T);

	exec doc.[Document.MainMaps] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

	-- from BASE!!!
	select [!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done], d.BindKind, d.BindFactor,
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Base
	from doc.Documents d 
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Base = @Id;

	with T as (select item from @rows group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], Article, Barcode,
		Price = cast(null as float), Rem = cast(null as float),
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit!] = u.Short, 
		[Role.Id!TItemRole!RefId] = i.[Role],
		[CostItem.Id!TCostItem!Id] = ir.[CostItem], [CostItem.Name!TCostItem!Name] = ci.[Name]
	from cat.Items i inner join T on i.Id = T.item and i.TenantId = @TenantId
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
		left join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
		left join cat.CostItems ci on i.TenantId = ci.TenantId and ir.CostItem = ci.Id
	where i.TenantId = @TenantId;

	with T as (select unit from @rows group by unit)
	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.Short
	from cat.Units u inner join T on u.Id = T.unit and u.TenantId = @TenantId
	where u.TenantId = @TenantId;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form]
	from doc.Operations o where TenantId = @TenantId and Form=@docform
	order by Id;

	select [States!TState!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color, Kind
	from doc.DocStates 
	where TenantId = @TenantId and Form = @docform
	order by [Order];

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [Params!TParam!Object] = null, [Operation] = @Operation, CheckRems = @CheckRems;

	select [!$System!] = null, [!!ReadOnly] = d.Done
	from doc.Documents d where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Order.Metadata]
as
begin
	set nocount on;
	exec doc.[Document.Stock.Metadata];
end
go
------------------------------------------------
create or alter procedure doc.[Document.Order.Update]
@TenantId int = 1,
@UserId bigint,
@Document cat.[Document.Stock.TableType] readonly,
@Extra cat.[Document.Extra.TableType] readonly,
@StockRows cat.[Document.Stock.Row.TableType] readonly,
@ServiceRows cat.[Document.Stock.Row.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	declare @id bigint;
	exec doc.[Document.Stock.UpdateBase] @TenantId = @TenantId, @UserId = @UserId,
		@Document = @Document, @Extra = @Extra,
		@StockRows = @StockRows, @ServiceRows = @ServiceRows, @RetId = @id output;
	exec doc.[Document.Order.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
/* Document Apply */
------------------------------------------------
create or alter procedure doc.[Document.Apply.Account.ByRows]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @exclude bit = 0;
	if 1 = (select IncludeServiceInCost from doc.DocumentExtra where TenantId = @TenantId and Id = @Id)
		set @exclude = 1;

	declare @trans table(TrNo int, RowNo int, DtCt smallint, Acc bigint, CorrAcc bigint, [Plan] bigint, 
		Detail bigint, Item bigint, RowMode nchar(1),
		Wh bigint, CashAcc bigint, [Date] date, Agent bigint, Company bigint, CostItem bigint,
		[Contract] bigint, CashFlowItem bigint, RespCenter bigint, Project bigint,
		Qty float, [Sum] money, ESum money, SumMode nchar(1), CostSum money, [ResultSum] money);

	-- DOCUMENT with ROWS
	with TR as (
		select 
			Dt = case ot.DtAccMode 
				when N'R' then ird.Account 
				when N'D' then irdocdt.Account
				else ot.Dt 
			end,
			Ct = case ot.CtAccMode 
				when N'R' then irc.Account
				when N'D' then irdocct.Account
				else ot.Ct 
			end,
			TrNo = ot.RowNo, dd.[RowNo], Detail = dd.Id, dd.[Item], Qty = dd.Qty * ot.Factor, [Sum] = dd.[Sum] * ot.Factor, 
			ESum = dd.ESum * ot.Factor,
			[Plan] = ot.[Plan], DtRow = isnull(ot.DtRow, N''), CtRow = isnull(ot.CtRow, N''),
			DtSum = isnull(ot.DtSum, N''), CtSum = isnull(ot.CtSum, N''),
			d.[Date], d.Agent, d.Company, d.RespCenter, dd.CostItem, d.WhFrom, d.WhTo, d.CashAccFrom, d.CashAccTo,
			d.[Contract], d.[CashFlowItem], d.Project
		from doc.DocDetails dd
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join doc.OpTrans ot on dd.TenantId = ot.TenantId and (dd.Kind = ot.RowKind or ot.RowKind = N'All')
			left join cat.ItemRoleAccounts ird on ird.TenantId = dd.TenantId and ird.[Role] = isnull(dd.ItemRoleTo, dd.ItemRole) and ird.AccKind = ot.DtAccKind and ird.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts irc on irc.TenantId = dd.TenantId and irc.[Role] = dd.ItemRole and irc.AccKind = ot.CtAccKind and irc.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts irdocdt on irdocdt.TenantId = d.TenantId and irdocdt.[Role] = d.ItemRole and irdocdt.AccKind = ot.DtAccKind and irdocdt.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts irdocct on irdocct.TenantId = d.TenantId and irdocct.[Role] = d.ItemRole and irdocct.AccKind = ot.CtAccKind and irdocct.[Plan] = ot.[Plan]
		where dd.TenantId = @TenantId and dd.Document = @Id and ot.Operation = @Operation 
			and (@exclude = 0 or Kind <> N'Service')
			--and (ot.DtRow = N'R' or ot.CtRow = N'R')
	)
	insert into @trans(TrNo, RowNo, DtCt, Acc, CorrAcc, [Plan], [Detail], Item, RowMode, Wh, CashAcc, 
		[Date], Agent, Company, RespCenter, Project, CostItem, [Contract],  CashFlowItem, Qty,[Sum], ESum, SumMode, CostSum, ResultSum)

	select TrNo, RowNo, DtCt = 1, Acc = Dt, CorrAcc = Ct, [Plan], Detail, Item, RowMode = DtRow, Wh = isnull(WhTo, WhFrom), CashAcc = CashAccTo,
		[Date], Agent, Company, RespCenter, Project, CostItem, [Contract], CashFlowItem, [Qty], [Sum], ESum, SumMode = DtSum, CostSum = 0, ResultSum = [Sum]
		from TR
	union all 
	select TrNo, RowNo, DtCt = -1, Acc = Ct, CorrAcc = Dt, [Plan], Detail, Item, RowMode = CtRow, Wh = isnull(WhFrom, WhTo), CashAcc = CashAccFrom,
		[Date], Agent, Company, RespCenter, Project, CostItem, [Contract], CashFlowItem, [Qty], [Sum], ESum, SumMode = CtSum, CostSum = 0, ResultSum = [Sum]
		from TR;

	if exists(select * from @trans where SumMode = N'S')
	begin
		-- calc self cost
		with W(item, ssum) as (
			select t.Item, [sum] = sum(j.[Sum]) / sum(j.Qty)
			from jrn.Journal j 
			  inner join @trans t on j.Item = t.Item and j.Account = t.Acc and j.DtCt = 1 and j.[Date] <= t.[Date]
			where j.TenantId = @TenantId and t.SumMode = N'S'
			group by t.Item
		)
		update @trans set CostSum = W.ssum * t.Qty
		from @trans t inner join W on t.Item = W.item
		where t.SumMode = N'S';
	end

	update @trans set ResultSum = 
		case SumMode
			when N'S' then CostSum
			when N'R' then [Sum] - CostSum
			when N'E' then [ESum]
			else [Sum]
		end,
		Qty = 
		case SumMode
			when N'E' then 0
			else Qty
		end;
	
	insert into jrn.Journal(TenantId, Document, Operation, Detail, TrNo, RowNo, [Date], DtCt, [Plan], Account, CorrAccount, [Sum], [Qty], [Item],
		Company, Agent, Warehouse, CashAccount, [Contract], CashFlowItem, CostItem, RespCenter, Project)
	select TenantId = @TenantId, Document = @Id, Operation = @Operation, Detail = iif(RowMode = N'R', Detail, null), TrNo, RowNo = iif(RowMode = N'R', RowNo, null),
		[Date], DtCt, [Plan], Acc, CorrAcc, [Sum] = sum([ResultSum]), Qty = sum(iif(RowMode = N'R', Qty, 0)),
		Item = iif(RowMode = N'R', Item, null),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter, Project
	from @trans
	group by TrNo, 
		iif(RowMode = N'R', RowNo, null),
		[Date], DtCt, [Plan], Acc, CorrAcc, 
		iif(RowMode = N'R', Item, null),
		iif(RowMode = N'R', Detail, null),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, 
		CostItem, RespCenter, Project
	having sum(ResultSum) <> 0 or sum(iif(RowMode = N'R', Qty, 0)) <> 0
	order by TrNo, RowNo;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.Account.ByDoc]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @trans table(TrNo int, DtCt smallint, Acc bigint, CorrAcc bigint, [Plan] bigint, 
		RowMode nchar(1),
		Wh bigint, CashAcc bigint, [Date] date, Agent bigint, Company bigint, RespCenter bigint, CostItem bigint,
		[Contract] bigint, CashFlowItem bigint, Project bigint, [Sum] money);

	with TR as (
		select 
			Dt = case ot.DtAccMode 
				when N'C' then iraccdt.Account
				when N'D' then irdocdt.Account
				else ot.Dt
			end,
			Ct  = case ot.CtAccMode 
				when N'C' then iraccct.Account
				when N'D' then irdocct.Account
				else ot.Ct
			end,
			TrNo = ot.RowNo, [Sum] = d.[Sum] * ot.Factor,
			[Plan] = ot.[Plan], DtRow = isnull(ot.DtRow, N''), CtRow = isnull(ot.CtRow, N''),
			d.[Date], d.Agent, d.Company, d.RespCenter, d.CostItem, d.WhFrom, d.WhTo, d.CashAccFrom, d.CashAccTo,
			d.[Contract], d.CashFlowItem, d.Project
		from doc.Documents d
			inner join doc.OpTrans ot on d.TenantId = ot.TenantId and ot.RowKind = N''
			left join cat.CashAccounts accdt on d.TenantId = accdt.TenantId and d.CashAccTo = accdt.Id
			left join cat.CashAccounts accct on d.TenantId = accct.TenantId and d.CashAccFrom = accct.Id
			left join cat.ItemRoleAccounts irdocdt on irdocdt.TenantId = d.TenantId and irdocdt.[Role] = d.ItemRole and irdocdt.AccKind = ot.DtAccKind and irdocdt.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts irdocct on irdocct.TenantId = d.TenantId and irdocct.[Role] = d.ItemRole and irdocct.AccKind = ot.CtAccKind and irdocct.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts iraccdt on iraccdt.TenantId = d.TenantId and iraccdt.[Role] = accdt.ItemRole and iraccdt.AccKind = ot.DtAccKind and iraccdt.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts iraccct on iraccct.TenantId = d.TenantId and iraccct.[Role] = accct.ItemRole and iraccct.AccKind = ot.CtAccKind and iraccct.[Plan] = ot.[Plan]
		where d.TenantId = @TenantId and d.Id = @Id and ot.Operation = @Operation
	)
	insert into @trans
	select TrNo, DtCt = 1, Acc = Dt, CorrAcc = Ct, [Plan], RowMode = DtRow, Wh = isnull(WhTo, WhFrom), CashAcc = CashAccTo,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, Project, [Sum]
		from TR
	union all 
	select TrNo, DtCt = -1, Acc = Ct, CorrAcc = Dt, [Plan], RowMode = CtRow, Wh = isnull(WhFrom, WhTo), CashAcc = CashAccFrom,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, Project, [Sum]
		from TR;

	insert into jrn.Journal(TenantId, Document, Operation, TrNo, [Date], DtCt, [Plan], Account, CorrAccount, [Sum],
		Company, Agent, Warehouse, CashAccount, [Contract], CashFlowItem, CostItem, RespCenter, Project)
	select TenantId = @TenantId, Document = @Id, Operation = @Operation, TrNo,
		[Date], DtCt, [Plan], Acc, CorrAcc, [Sum] = sum([Sum]),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter, Project
	from @trans
	group by TrNo, [Date], DtCt, [Plan], Acc, CorrAcc, 
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter, Project
end
go
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
	set ansi_warnings off;

	-- ensure empty journal
	delete from jrn.Journal where TenantId = @TenantId and Document = @Id;

	declare @mode nvarchar(10) = N'bydoc';

	if exists(select * from doc.DocDetails where TenantId = @TenantId and Document = @Id)
		exec doc.[Document.Apply.Account.ByRows] @TenantId = @TenantId, @UserId = @UserId, @Operation = @Operation, @Id = @Id
	else
		exec doc.[Document.Apply.Account.ByDoc] @TenantId = @TenantId, @UserId = @UserId, @Operation = @Operation, @Id = @Id
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
	set transaction isolation level read committed;


	with TX as 
	(
		select Document = d.Id, Dir = 1, Detail = dd.Id, d.Company, Warehouse = isnull(d.WhTo, d.WhFrom), dd.Item, Qty = dd.Qty * js.Factor, [Sum] = dd.[Sum] * js.Factor, 
			Kind = isnull(dd.Kind, N''), CostItem = isnull(dd.CostItem, d.CostItem), RespCenter, d.Agent, d.[Contract], d.Project
		from doc.DocDetails dd 		
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join doc.OpStore js on js.TenantId = d.TenantId and js.Operation = d.Operation and js.IsIn = 1
		where d.TenantId = @TenantId and d.Id = @Id
		union all
		select Document = d.Id, Dir = -1, Detail = dd.Id, d.Company, Warehouse = isnull(d.WhFrom, d.WhTo), dd.Item, Qty = dd.Qty * js.Factor, [Sum] = dd.[Sum] * js.Factor, 
			Kind = isnull(dd.Kind, N''), CostItem = isnull(dd.CostItem, d.CostItem), RespCenter, d.Agent, d.[Contract], d.Project
		from doc.DocDetails dd 		
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join doc.OpStore js on js.TenantId = d.TenantId and js.Operation = d.Operation and js.IsOut = 1
		where d.TenantId = @TenantId and d.Id = @Id
	)
	insert into jrn.StockJournal(TenantId, Dir, Document, Operation, Warehouse, Detail, Company, Item, Qty, [Sum], CostItem, 
		RespCenter, Agent, [Contract], Project)
	select @TenantId, Dir, Document, @Operation, Warehouse, Detail, Company, Item, Qty, [Sum], CostItem,
		RespCenter, Agent, [Contract], Project
	from TX;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.Cash]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from jrn.CashJournal where TenantId = @TenantId and Document = @Id;

	with T as
	(
		select InOut = 1, Document = d.Id, d.[Date], d.Company, d.Agent, d.[Contract], CashAcc = isnull(d.CashAccTo, d.CashAccFrom), [Sum] = d.[Sum] * oc.Factor, d.CostItem, d.RespCenter, d.Project, 
			d.CashFlowItem
		from doc.Documents d
			inner join doc.OpCash oc on oc.TenantId = @TenantId and d.Operation = oc.Operation
		where d.TenantId = @TenantId and d.Id = @Id and oc.IsIn = 1
		union all
		select InOut = -1, Document = d.Id, d.[Date], d.Company, d.Agent, d.[Contract], CashAcc = isnull(d.CashAccFrom, d.CashAccTo), [Sum] = d.[Sum] * oc.Factor, d.CostItem, d.RespCenter, d.Project, 
			d.CashFlowItem
		from doc.Documents d
			inner join doc.OpCash oc on oc.TenantId = @TenantId and d.Operation = oc.Operation
		where d.TenantId = @TenantId and d.Id = @Id and oc.IsOut = 1
	)
	insert into jrn.CashJournal(TenantId, Document, Operation, [Date], InOut, [Sum], Company, Agent, [Contract], CashAccount, CashFlowItem, RespCenter, Project)
	select TenantId = @TenantId, Document = @Id, Operation = @Operation, [Date], InOut, [Sum], Company, Agent, [Contract], CashAcc, CashFlowItem, RespCenter, Project
	from T;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.Settle]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from jrn.SettleJournal where TenantId = @TenantId and Document = @Id;

	with T as
	(
		select IncDec = 1, Document = d.Id, d.[Date], d.Company, d.Agent, d.[Contract], [Sum] = d.[Sum] * oc.Factor, d.CostItem, d.RespCenter, d.Project
		from doc.Documents d
			inner join doc.OpSettle oc on oc.TenantId = @TenantId and d.Operation = oc.Operation
		where d.TenantId = @TenantId and d.Id = @Id and oc.IsInc = 1
		union all
		select InOut = -1, Document = d.Id, d.[Date], d.Company, d.Agent, d.[Contract], [Sum] = d.[Sum] * oc.Factor, d.CostItem, d.RespCenter, d.Project
		from doc.Documents d
			inner join doc.OpSettle oc on oc.TenantId = @TenantId and d.Operation = oc.Operation
		where d.TenantId = @TenantId and d.Id = @Id and oc.IsDec = 1
	)
	insert into jrn.SettleJournal(TenantId, Document, Operation, [Date], IncDec, [Sum], Company, Agent, [Contract], RespCenter, Project)
	select TenantId = @TenantId, Document = @Id, Operation = @Operation, [Date], IncDec, [Sum], Company, Agent, [Contract], RespCenter, Project
	from T;
end
go
------------------------------------------------
create or alter procedure doc.[Apply.WriteSupplierPrices]
@TenantId int = 1,
@UserId bigint, 
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	with T as(
		select Document = d.Id, Detail = dd.Id, dd.Item, d.Agent, [Date] = cast(d.[Date] as date), dd.Price 
		from doc.DocDetails dd
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join cat.ItemRoles ir on dd.TenantId = ir.TenantId and dd.ItemRole = ir.Id
		where dd.TenantId = @TenantId and dd.Document = @Id and ir.HasPrice = 1
	)
	merge jrn.SupplierPrices as t
	using T as s
	on t.[Date] = s.[Date] and t.Item = s.Item and t.TenantId = @TenantId
	when matched then update set
		t.Document = s.Document,
		t.Detail = s.Detail,
		t.Agent = s.Agent,
		t.Price = isnull(s.Price, 0)
	when not matched by target then insert
		(TenantId, [Date], Agent, Document, Detail, Item, Price) values
		(@TenantId, s.[Date], s.[Agent], s.Document, s.Detail, s.Item, isnull(s.Price, 0));
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.CheckRems]
@TenantId int = 1,
@Id bigint,
@CheckRems bit
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set @CheckRems = app.fn_IsCheckRems(@TenantId, @CheckRems);
	if @CheckRems = 1
	begin
		declare @res table(Item bigint, [Role] bigint, Qty float);
		with TD as
		(
			select Item, [Role] = dd.ItemRole, Qty = sum(Qty) from doc.DocDetails dd
			where dd.TenantId = @TenantId and dd.Document = @Id and dd.Kind = N'Stock'
			group by Item, dd.ItemRole
		)
		insert into @res(Item, [Role], Qty) select Item, [Role], Qty from TD;

		if exists(
			select * 
			from @res dd left join doc.fn_getDocumentRems(@CheckRems, @TenantId, @Id) t on dd.Item = t.Item and dd.[Role] = t.[Role]
			where dd.Qty > isnull(t.Rem, 0)
		)
		throw 60000, N'UI:@[Error.InsufficientAmount]', 0;
	end
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
	begin tran;
	delete from jrn.StockJournal where TenantId = @TenantId and Document = @Id;
	delete from jrn.Journal where TenantId = @TenantId and Document = @Id;
	delete from jrn.CashJournal where TenantId= @TenantId and Document = @Id;
	delete from jrn.SettleJournal where TenantId = @TenantId and Document = @Id;
	delete from jrn.SupplierPrices where TenantId = @TenantId and Document = @Id;
	update doc.Documents set Done = 0, DateApplied = null
		where TenantId = @TenantId and Id = @Id;
	commit tran;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@CheckRems bit = 0
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @operation bigint;
	declare @done bit;
	declare @wsp bit;
	declare @base bigint;

	select @operation = d.Operation, @done = d.Done, @wsp = de.WriteSupplierPrices, 
		@base = d.Base
	from doc.Documents d
		left join doc.DocumentExtra de on d.TenantId = de.TenantId and d.Id = de.Id
	where d.TenantId = @TenantId and d.Id=@Id;

	if 1 = @done
		throw 60000, N'UI:@[Error.Document.AlreadyApplied]', 0;

	declare @stock bit;  -- stock journal
	declare @pay bit;    -- pay journal
	declare @acc bit;    -- acc journal
	declare @cash bit;   -- cash journal
	declare @settle bit; -- settle journal

	if exists(select * from doc.OpStore 
			where TenantId = @TenantId and Operation = @operation and (IsIn = 1 or IsOut = 1))
		set @stock = 1;
	if exists(select * from doc.OpTrans 
			where TenantId = @TenantId and Operation = @operation)
		set @acc = 1;
	if exists(select * from doc.OpCash 
			where TenantId = @TenantId and Operation = @operation and (IsIn = 1 or IsOut = 1))
		set @cash = 1;
	if exists(select * from doc.OpSettle 
			where TenantId = @TenantId and Operation = @operation and (IsInc = 1 or IsDec = 1))
		set @settle = 1;

	begin tran;
		exec doc.[Document.Apply.CheckRems] @TenantId= @TenantId, @Id=@Id, @CheckRems = @CheckRems;
		if @stock = 1
			exec doc.[Document.Apply.Stock] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @acc = 1
			exec doc.[Document.Apply.Account] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @cash = 1
			exec doc.[Document.Apply.Cash] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @settle = 1
			exec doc.[Document.Apply.Settle] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @wsp = 1
			exec doc.[Apply.WriteSupplierPrices] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

		update doc.Documents set Done = 1, DateApplied = getdate() 
			where TenantId = @TenantId and Id = @Id;
	commit tran;
end
go
------------------------------------------------
create or alter procedure jrn.[ReApply.Cash]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from jrn.CashJournal where TenantId = @TenantId;
	delete from jrn.CashReminders where TenantId = @TenantId;

	with T as
	(
		select InOut = 1, Document = d.Id, d.[Date], d.Company, d.Agent, d.[Contract], CashAcc = isnull(d.CashAccTo, d.CashAccFrom), [Sum] = d.[Sum] * oc.Factor, d.CostItem, d.RespCenter, d.Project, 
			d.CashFlowItem, d.Operation
		from doc.Documents d
			inner join doc.OpCash oc on oc.TenantId = @TenantId and d.Operation = oc.Operation
		where d.TenantId = @TenantId and oc.IsIn = 1 and d.Done = 1
		union all
		select InOut = -1, Document = d.Id, d.[Date], d.Company, d.Agent, d.[Contract], CashAcc = isnull(d.CashAccFrom, d.CashAccTo), [Sum] = d.[Sum] * oc.Factor, d.CostItem, d.RespCenter, d.Project, 
			d.CashFlowItem, d.Operation
		from doc.Documents d
			inner join doc.OpCash oc on oc.TenantId = @TenantId and d.Operation = oc.Operation
		where d.TenantId = @TenantId and oc.IsOut = 1 and d.Done = 1
	)
	insert into jrn.CashJournal(TenantId, Document, Operation, [Date], InOut, [Sum], Company, Agent, [Contract], CashAccount, CashFlowItem, RespCenter, Project)
	select TenantId = @TenantId, Document, Operation, [Date], InOut, [Sum], Company, Agent, [Contract], CashAcc, CashFlowItem, RespCenter, Project
	from T;
end
go


/* Document.Dialogs */
------------------------------------------------
/*
здесь было с УЧЕТОМ аналитики по счетам!
create or alter view doc.[view.Document.Transactions]
as
select [!TTransPart!Array] = null, [Id!!Id] = j.Id,
	[Account.Code!TAccount!] = a.Code, j.[Sum], j.Qty,
	[Item.Id!TItem!Id] = i.Id, [Item.Name!TItem] = i.[Name],
	[Warehouse.Id!TWarehouse!Id] = w.Id, [Warehouse.Name!TWarehouse] = w.[Name],
	[Agent.Id!TAgent!Id] = g.Id, [Agent.Name!TAgent] = g.[Name],
	[CashAcc.Id!TCashAcc!Id] = ca.Id, [CashAcc.Name!TCashAcc] = ca.[Name], 
	[CashAcc.No!TCashAcc!] = ca.AccountNo, [CashAcc.IsCash!TCashAcc!] = ca.IsCashAccount,
	[Contract.Id!TContract!Id] = c.Id, [Contract.Name!TContract!Name] = c.[Name],
	[CashFlowItem.Id!TCashFlowItem!Id] = cf.Id, [CashFlowItem.Name!TCashFlowItem!Name] = cf.[Name],
	[CostItem.Id!TCostItem!Id] = ci.Id, [CostItem.Name!TCostItem!Name] = ci.[Name],
	[RespCenter.Id!TRespCenter!Id] = rc.Id, [RespCenter.Name!TRespCenter!Name] = rc.[Name],
	[!TenantId] = j.TenantId, [!Document] = j.Document, [!DtCt] = j.DtCt, [!TrNo] = j.TrNo, [!RowNo] = j.RowNo
from jrn.Journal j 
	inner join acc.Accounts a on j.TenantId = a.TenantId and j.Account = a.Id
	left join cat.Items i on j.TenantId = i.TenantId and j.Item = i.Id and a.IsItem = 1
	left join cat.Warehouses w on j.TenantId = w.TenantId and j.Warehouse = w.Id and a.IsWarehouse = 1
	left join cat.Agents g on j.TenantId = g.TenantId and j.Agent = g.Id and a.IsAgent = 1
	left join doc.Contracts c on j.TenantId = c.TenantId and j.[Contract] = c.Id and a.IsContract = 1
	left join cat.CashAccounts ca on j.TenantId = ca.TenantId and j.CashAccount = ca.Id and (a.IsCash = 1 or a.IsBankAccount = 1)
	left join cat.CashFlowItems cf on j.TenantId = cf.TenantId and j.CashFlowItem = cf.Id  and (a.IsCash = 1 or a.IsBankAccount = 1)
	left join cat.CostItems ci on j.TenantId = ci.TenantId and j.CostItem = ci.Id and a.IsCostItem = 1
	left join cat.RespCenters rc on j.TenantId = rc.TenantId and j.RespCenter = rc.Id and a.IsRespCenter = 1
go
*/

create or alter view doc.[view.Document.Transactions]
as
select [!TTransPart!Array] = null, [Id!!Id] = j.Id,
	[Account.Code!TAccount!] = a.Code, j.[Sum], j.Qty,
	[Item!TItem!RefId] = j.Item, [Warehouse!TWarehouse!RefId] = j.Warehouse,
	[Agent!TAgent!RefId] = j.Agent,
	[CashAcc.Id!TCashAcc!Id] = ca.Id, [CashAcc.Name!TCashAcc] = ca.[Name], 
	[CashAcc.No!TCashAcc!] = ca.AccountNo, [CashAcc.IsCash!TCashAcc!] = ca.IsCashAccount,
	[Contract.Id!TContract!Id] = c.Id, [Contract.Name!TContract!Name] = c.[Name],
	[CashFlowItem.Id!TCashFlowItem!Id] = cf.Id, [CashFlowItem.Name!TCashFlowItem!Name] = cf.[Name],
	[CostItem!TCostItem!RefId] = j.CostItem, [RespCenter!TRespCenter!RefId] = j.RespCenter,
	[Company!TCompany!RefId] = j.Company,
	[!TenantId] = j.TenantId, [!Document] = j.Document, [!DtCt] = j.DtCt, [!TrNo] = j.TrNo, [!RowNo] = j.RowNo
from jrn.Journal j 
	inner join acc.Accounts a on j.TenantId = a.TenantId and j.Account = a.Id
	left join doc.Contracts c on j.TenantId = c.TenantId and j.[Contract] = c.Id and a.IsContract = 1
	left join cat.CashAccounts ca on j.TenantId = ca.TenantId and j.CashAccount = ca.Id and (a.IsCash = 1 or a.IsBankAccount = 1)
	left join cat.CashFlowItems cf on j.TenantId = cf.TenantId and j.CashFlowItem = cf.Id  and (a.IsCash = 1 or a.IsBankAccount = 1)
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

	declare @refs table(comp bigint, item bigint, respcenter bigint, costitem bigint, 
		account bigint, wh bigint, agent bigint, [contract] bigint, cashacc bigint, cashflowitem bigint,
		project bigint);

	select [Transactions!TTrans!Array] = null, [Id!!Id] = TrNo, [Plan] = a.Code,
		[Dt!TTransPart!Array] = null, [Ct!TTransPart!Array] = null
	from jrn.Journal j
		inner join acc.Accounts a on j.TenantId = a.TenantId and j.[Plan] = a.Id
	where j.TenantId = @TenantId and j.Document = @Id
	group by [TrNo], a.Code
	order by a.Code, TrNo;

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

	-- store
	select [StoreTrans!TStoreTrans!Array] = null, [Id!!Id] = Id, Dir, Qty, [Sum],
		[Company!TCompany!RefId] = Company, [Item!TItem!RefId] = Item, [Warehouse!TWarehouse!RefId] = Warehouse,
		[CostItem!TCostItem!RefId] = CostItem, [RespCenter!TRespCenter!RefId] = RespCenter,
		[Agent!TAgent!RefId] = Agent, [Contract!TContract!RefId] = [Contract],
		[Project!TProject!RefId] = Project
	from jrn.StockJournal
	where TenantId = @TenantId and [Document] = @Id
	order by Dir;

	-- cash
	select [CashTrans!TCashTrans!Array] = null, [Id!!Id] = Id, InOut, [Sum],
		[Company!TCompany!RefId] = Company, [CashAccount!TCashAccount!RefId] = CashAccount,
		[CashFlowItem!TCashFlowItem!RefId] = CashFlowItem, [RespCenter!TRespCenter!RefId] = RespCenter,
		[Agent!TAgent!RefId] = Agent, [Contract!TContract!RefId] = [Contract],
		[Project!TProject!RefId] = Project
	from jrn.CashJournal
	where TenantId = @TenantId and [Document] = @Id;

	-- settle
	select [SettleTrans!TSettleTrans!Array] = null, [Id!!Id] = Id, IncDec, [Sum],
		[Company!TCompany!RefId] = Company,[RespCenter!TRespCenter!RefId] = RespCenter,
		[Agent!TAgent!RefId] = Agent, [Contract!TContract!RefId] = [Contract],
		[Project!TProject!RefId] = Project
	from jrn.SettleJournal
	where TenantId = @TenantId and [Document] = @Id;

	-- maps
	insert into @refs(comp, item, costitem, respcenter, agent, wh, [contract], cashacc, project)
	select Company, Item, CostItem, RespCenter, Agent, Warehouse, [Contract], CashAccount, Project
	from jrn.Journal
	where TenantId = @TenantId and Document = @Id;

	insert into @refs(comp, item, costitem, respcenter, wh, agent, [contract], project)
	select Company, Item, CostItem, RespCenter, Warehouse, Agent, [Contract], Project
	from jrn.StockJournal
	where TenantId = @TenantId and Document = @Id;
	
	insert into @refs(comp, cashflowitem, respcenter, agent, [contract], cashacc, project)
	select Company, CashFlowItem, RespCenter, Agent, [Contract], CashAccount, Project
	from jrn.CashJournal
	where TenantId = @TenantId and Document = @Id;

	with TC as (select comp from @refs group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join TC t on c.TenantId = @TenantId and c.Id = t.comp;

	with TCA as (select cashacc from @refs group by cashacc)
	select [!TCashAccount!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.CashAccounts c inner join TCA t on c.TenantId = @TenantId and c.Id = t.cashacc;

	with TW as (select wh from @refs group by wh)
	select [!TWarehouse!Map] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name]
	from cat.Warehouses w inner join TW t on w.TenantId = @TenantId and w.Id = t.wh;

	with TI as (select item from @refs group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name]
	from cat.Items i inner join TI t on i.TenantId = @TenantId and i.Id = t.item;

	with TR as (select respcenter from @refs group by respcenter)
	select [!TRespCenter!Map] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
	from cat.RespCenters r inner join TR t on r.TenantId = @TenantId and r.Id = t.respcenter;

	with TA as (select agent from @refs group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA t on a.TenantId = @TenantId and a.Id = t.agent;

	with TCF as (select cashflowitem from @refs group by cashflowitem)
	select [!TCashFlowItem!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.CashFlowItems c inner join TCF t on c.TenantId = @TenantId and c.Id = t.cashflowitem;

	with TP as (select project from @refs group by project)
	select [!TProject!Map] = null, [Id!!Id] = p.Id, [Name!!Name] = p.[Name]
	from cat.Projects p inner join TP t on p.TenantId = @TenantId and p.Id = t.project;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Base.Select.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Agent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;	
	declare @op bigint, @baseop bigint;

	select @op = Operation from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	select @baseop = ol.Parent from doc.OperationLinks ol
	inner join doc.Operations op on ol.TenantId = op.TenantId and ol.Parent = op.Id
	inner join doc.OperationKinds pk on ol.TenantId = pk.TenantId and op.Kind = pk.Id
	and pk.LinkType = N'B' and ol.Operation = @op;

	declare @docs table (id bigint, agent bigint);
	insert into @docs (id, agent) 
	select Id, Agent from doc.Documents d
	where TenantId = @TenantId and Operation = @baseop and
		(@Agent is null or d.Agent = @Agent);		

	-- field set as TLinkedDoc
	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[No], d.SNo, d.[Date], d.[Sum], d.[Memo],
		d.Done, OpName = o.[Name], o.DocumentUrl, o.Form,
		[Agent!TAgent!RefId] = d.Agent, [LinkedDocs!TDocBase!Array] = null
	from doc.Documents d inner join @docs t on d.TenantId = @TenantId and d.Id = t.id
	inner join doc.Operations o on o.TenantId = d.TenantId and d.Operation = o.Id;

	-- arrays
	-- from BASE!!!
	select [!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done], d.BindKind, d.BindFactor,
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Base
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and t.id = d.Base
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Base = t.id;

	with T as (
		select agent from @docs group by agent
	)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from T inner join cat.Agents a on T.agent = a.Id and a.TenantId = @TenantId;

	-- filters
	select [!$System!] = null,
		[!Documents.Agent.Id!Filter] = @Agent, [!Documents.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent);

	/*
	select [!TBind!Object] = null, [!TDocument.Bind!ParentId] = [Base], [Payment], [Shipment] 
	from (
		select [Base], Kind = r.BindKind, [Sum] = [Sum] * r.BindFactor
		from doc.Documents r 
		inner join @docs t on r.TenantId = @TenantId and r.Base = t.id
	) 
	as s pivot (  
		sum([Sum])  
		for Kind in ([Payment], [Shipment])  
	) as p;  
	*/
end
go

/* Document Commands */
------------------------------------------------
create or alter procedure doc.[Document.CreateOnBase.BySum]
@TenantId int = 1,
@UserId bigint,
@LinkId bigint,
@Document bigint,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @rtable table(id bigint, op bigint);

	declare @operation bigint, @parent bigint, @linktype nchar(1), @linkkind nvarchar(16), @factor smallint;
	select @parent = ol.Parent, @operation = ol.Operation, @linktype = okpr.LinkType, @linkkind = okch.Kind, @factor = okch.Factor
	from doc.OperationLinks ol 
		inner join doc.Operations opr on ol.TenantId = opr.TenantId and ol.Parent = opr.Id
		inner join doc.Operations och on ol.TenantId = och.TenantId and ol.Operation = och.Id
		left join doc.OperationKinds okpr on ol.TenantId = okpr.TenantId and opr.Kind = okpr.Id
		left join doc.OperationKinds okch on ol.TenantId = okch.TenantId and och.Kind = okch.Id
	where ol.TenantId = @TenantId and ol.Id = @LinkId;

	declare @BaseDoc bigint;
	declare @ParentDoc bigint;
	if @linktype = N'P'
	begin
		-- base = base from parent
		select @BaseDoc = Base, @ParentDoc = @Document from doc.Documents where TenantId = @TenantId and Id = @Document;
	end
	else if @linktype = N'B'
	begin
		-- base = parent
		set @BaseDoc = @Document;
		set @ParentDoc = @Document;
	end

	declare @alreadysum money, @baseSum money;
	select @baseSum = isnull([Sum], 0) from doc.Documents d where d.TenantId = @TenantId and d.Id = @BaseDoc;
	-- calc remainder sum
	select @alreadysum = isnull(sum(d.[Sum] * d.BindFactor), 0) 
		from doc.Documents d where TenantId = @TenantId and d.Temp = 0 and
			Base = @BaseDoc and d.BindKind = @linkkind;

	insert into doc.Documents (TenantId, [Date], Operation, Parent, Base, BindKind, BindFactor, OpLink, Company, Agent, [Contract], [RespCenter], 
		PriceKind, WhFrom, WhTo, Currency, UserCreated, Temp, [Sum])
	output inserted.Id, inserted.Operation into @rtable(id, op)
	select @TenantId, cast(getdate() as date), @operation, @ParentDoc, @BaseDoc, @linkkind, @factor, @LinkId, Company, Agent, [Contract], [RespCenter], 
		PriceKind, WhFrom, WhTo, Currency, @UserId, 1, @baseSum - @alreadysum
	from doc.Documents where TenantId = @TenantId and Id = @Document and Operation = @parent;

	select [Document!TDocBase!Object] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done],
		[OpName] = o.[Name], [Form] = o.Form, [DocumentUrl] = o.DocumentUrl
	from @rtable t inner join doc.Documents d on d.TenantId = @TenantId and t.id = d.Id
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id

	select top(1) @RetId = id from @rtable;
end
go
------------------------------------------------
create or alter procedure doc.[Document.CreateOnBase.ByRows]
@TenantId int = 1,
@UserId bigint,
@LinkId bigint,
@Document bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @newid bigint;

	exec doc.[Document.CreateOnBase.BySum] @TenantId = @TenantId, @UserId = @UserId, @LinkId = @LinkId, @Document = @Document,
		@RetId = @newid output;

	insert into doc.DocDetails (TenantId, Document, RowNo, Kind, Item, ItemRole, Unit, Qty, Price, [Sum], Memo,
		CostItem, ESum, DSum, TSum)
	select @TenantId, @newid, RowNo, Kind, Item, ItemRole, Unit, Qty, Price, [Sum], Memo,
		CostItem, ESum, DSum, TSum
	from doc.DocDetails where TenantId = @TenantId and Document = @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.CreateOnBase]
@TenantId int = 1,
@UserId bigint,
@Document bigint,
@LinkId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @type nvarchar(16);
	select @type = [Type] from doc.OperationLinks where TenantId = @TenantId and Id = @LinkId;
	if @type = N'BySum'
		exec doc.[Document.CreateOnBase.BySum] @TenantId = @TenantId, @UserId = @UserId, @LinkId = @LinkId, @Document = @Document;
	else if @type = N'ByRows'
		exec doc.[Document.CreateOnBase.ByRows] @TenantId = @TenantId, @UserId = @UserId, @LinkId = @LinkId, @Document = @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Copy]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @rtable table(id bigint);
	declare @newid bigint;

	begin tran;

	insert into doc.Documents (TenantId, Temp, [Date],  Operation, [Sum],  SNo, Company, Agent, [Contract], Currency, 
		WhFrom, WhTo, CashAccFrom, CashAccTo, RespCenter, ItemRole, CostItem, CashFlowItem, PriceKind, Notice, Memo, 
		UserCreated)
	output inserted.Id into @rtable(id)
	select @TenantId, 1, [Date], Operation, [Sum], SNo, Company, Agent, [Contract], Currency, 
		WhFrom, WhTo, CashAccFrom, CashAccTo, RespCenter, ItemRole, CostItem, CashFlowItem, PriceKind, Notice, Memo,
		@UserId
	from doc.Documents where TenantId = @TenantId and Id = @Id;
	
	select @newid = id from @rtable;

	insert into doc.DocDetails (TenantId, Document, RowNo, Kind, Item, ItemRole, ItemRoleTo, Unit,
		Qty, FQty, Price, [Sum], ESum, DSum, TSum, Memo, CostItem)
	select @TenantId, @newid, RowNo, Kind, Item, ItemRole, ItemRoleTo, Unit,
		Qty, FQty, Price, [Sum], ESum, DSum, TSum, Memo, CostItem
	from doc.DocDetails where TenantId = @TenantId and Document = @Id;
	commit tran;

	select [Document!TDocCopy!Object] = null, Id = @newid, o.DocumentUrl
	from doc.Documents d inner join doc.Operations o on d.TenantId = @TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Id = @newid;

end
go
------------------------------------------------
create or alter procedure doc.[Document.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @done bit;
	select @done = Done from doc.Documents where TenantId = @TenantId and Id=@Id;
	if @done = 1
		throw 600000, N'@[Error.Document.AlreadyApplied]', 0
	else
	begin
		begin tran;
		delete from doc.DocDetails where TenantId = @TenantId and Document=@Id;
		delete from doc.DocumentExtra where TenantId = @TenantId and Id=@Id;
		update doc.Documents set Base = null, BindKind = null, BindFactor = null where TenantId = @TenantId and Base = @Id;
		update doc.Documents set Parent = null where TenantId = @TenantId and Parent = @Id;
		delete from doc.Documents where TenantId = @TenantId and Id=@Id;
		commit tran;
	end
end
go
-------------------------------------------------
create or alter procedure doc.[ItemRole.Rem.Get]
@TenantId int = 1,
@UserId bigint,
@Item bigint = null,
@Role bigint = null,
@Date datetime = null,
@CheckRems bit = 1,
@Wh bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @elems a2sys.[Id.TableType];
	insert into @elems (Id) values (@Item);

	select [Result!TRem!Object] = null, r.Item, r.Rem, r.[Role]
	from doc.fn_getItemsRems(@CheckRems, @TenantId, @elems, @Date, @Wh) r
	where r.[Role] = @Role;
end
go
-------------------------------------------------
create or alter procedure doc.[Document.Base.Set]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Base bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	-- assigns Base, BindKind, BindFactor

	declare @parentOp bigint;
	select @parentOp = Operation from doc.Documents where TenantId = @TenantId and Id = @Base;

	declare @kind nvarchar(16), @factor smallint;
	select @kind = ok.Kind, @factor = ok.Factor
	from doc.Documents d inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		inner join doc.OperationKinds ok on ok.TenantId = o.TenantId and ok.Id = o.Kind
		inner join doc.OperationLinks ol on ol.TenantId = o.TenantId and ol.Operation = d.Operation
	where d.Id = @Id and ol.Parent = @parentOp;

	if @kind is null or @factor is null
		throw 60000, N'[Document.Base.Set]. Internal error', 0;

	update doc.Documents set Base = @Base, BindKind = @kind, BindFactor = @factor
	where TenantId = @TenantId and Id = @Id;
end
go

-------------------------------------------------
create or alter procedure doc.[Document.Base.Clear]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update doc.Documents set Base = null, BindKind = null, BindFactor = null 
	where TenantId = @TenantId and Id = @Id;
end
go

------------------------------------------------
create or alter procedure doc.[Document.SetState]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@State bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update doc.Documents set [State] = @State where TenantId = @TenantId and Id = @Id;
end
go


------------------------------------------------
create or alter procedure doc.[Document.Print.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PrintForms!TPrintForm!Array] = null, [Id!!Id] = 0, DocumentId = @Id,		
		[Name!!Name] = pf.[Name], pf.Category, pf.[Url], pf.Report
	from.doc.Documents d
		inner join doc.Operations op on d.TenantId = op.TenantId and d.Operation = op.Id
		inner join doc.OpPrintForms lnk on op.TenantId = lnk.TenantId and lnk.Operation = op.Id
		inner join doc.PrintForms pf on lnk.TenantId = pf.TenantId and lnk.PrintForm = pf.Id
	where d.TenantId = @TenantId and d.Id = @Id
	order by pf.[Order];
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Report]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- all rows

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date] = d.[Date], d.SNo, d.Memo,
		d.[Sum], [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, [WhFrom!TWarehouse!RefId] = d.WhFrom,
		[WhTo!TWarehouse!RefId] = d.WhTo, [Contract!TContract!RefId] = d.[Contract], 
		[Rows!TRow!Array] = null
	from doc.Documents d
	where TenantId = @TenantId and Id = @Id;

	declare @rows table(id bigint, item bigint, unit bigint, rowno int);
	insert into @rows (id, item, unit, rowno)
	select Id, Item, Unit, row_number() over(order by dd.Kind desc, RowNo)
	from doc.DocDetails dd	
	where dd.TenantId = @TenantId and dd.Document = @Id;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], Price, [Sum], ESum, DSum, TSum,
		[Item!TItem!RefId] = dd.Item, [Unit!TUnit!RefId] = dd.Unit, 
		[!TDocument.Rows!ParentId] = dd.Document, [RowNo!!RowNumber] = r.rowno
	from doc.DocDetails dd
		inner join @rows r on dd.Id = r.id
	where dd.TenantId=@TenantId and dd.Document = @Id
	order by r.rowno;

	-- maps
	select [!TWarehouse!Map] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name]
	from cat.Warehouses w inner join doc.Documents d on d.TenantId = w.TenantId and w.Id in (d.WhFrom, d.WhTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by w.Id, w.[Name];

	with TA as (
		select Agent from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id
		union all
		select c.Agent from doc.Documents d inner join doc.Contracts c on c.TenantId = d.TenantId and c.Id = d.[Contract]
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a
	where a.TenantId = @TenantId and a.Id in (select Agent from TA);

	with CA as(
		select Company from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id
		union all
		select c.Company from doc.Documents d inner join doc.Contracts c on c.TenantId = d.TenantId and c.Id = d.[Contract]
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name],
		[Logo.Stream!TImage!] = lb.[Stream], [Logo.Mime!TImage!] = lb.Mime
	from cat.Companies c 
		inner join doc.Documents d on d.TenantId = c.TenantId and d.Company = c.Id
		left join app.Blobs lb on lb.TenantId = c.TenantId and c.Logo = lb.Id
	where c.TenantId = @TenantId and d.Id = @Id;

	--exec doc.[Document.MainMaps] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

	with T as (select item from @rows group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], Article, Barcode
	from cat.Items i inner join T on i.Id = T.item and i.TenantId = @TenantId
	where i.TenantId = @TenantId;

	with T as (select unit from @rows group by unit)
	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.Short
	from cat.Units u inner join T on u.Id = T.unit and u.TenantId = @TenantId
	where u.TenantId = @TenantId;
end
go
-- SALES.PRICE
-------------------------------------------------
create or alter procedure doc.[Price.Index]
@TenantId int = 1,
@UserId bigint,
@Group bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	if @Group is null
		select top(1) @Group = Id from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id = [Root] and Id <> 0;

	with T(Id, _order, [Name], HasChildren, Icon)
	as (
		select Id = -1, 0, [Name] = N'@[NoGrouping]', 0, Icon=N'package-outline'
		union all
		-- hack = negative!
		select Id = -@Group, 2, [Name] = N'@[WithoutGroup]', 0, Icon=N'ban' where @Group is not null
		union all
		select Id, 1, [Name],
			HasChildren= case when exists(
				select 1 from cat.ItemTree it where it.Void = 0 
				and it.Parent = t.Id and it.TenantId = @TenantId and t.TenantId = @TenantId
			) then 1 else 0 end,
			Icon = N'folder-outline'
		from cat.ItemTree t
			where t.TenantId = @TenantId and t.Void = 0 and t.Parent = @Group
	)
	select [Groups!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon,
		/*nested folders - lazy*/
		[Items!TGroup!Items] = null, 
		/* marker: subfolders exist */
		[HasSubItems!!HasChildren] = HasChildren,
		/*nested items (not folders!) */
		[Prices!TPriceItem!LazyArray] = null
	from T
	order by _order, [Id];

	select [Checked!TChecked!Object] = null, 
		[PriceKind1!TPriceKind!RefId] = [1], 
		[PriceKind2!TPriceKind!RefId] = [2], 
		[PriceKind3!TPriceKind!RefId] = [3] 
	from (
		select top(3) Id, RowNo = row_number() over(order by Id) from cat.PriceKinds
		where TenantId = @TenantId and Void = 0
	) t pivot (sum(Id) for RowNo in ([1], [2], [3])) pvt;

	select [PriceKinds!TPriceKind!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.PriceKinds where TenantId = @TenantId and Void = 0
	order by Id;

	-- Prices definition
	select [!TPriceItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode, i.IsVariant,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short, ParentItemId = i.Parent,
		[Values!TPriceValue!Array] = null
	from cat.Items i
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	where 0 <> 0;

	select [!TPriceValue] = null, p.Price, p.PriceKind, [Date] = p.[Date], [!TPriceItem.Values!ParentId] = p.Item
	from doc.Prices p where 0 <> 0;

	-- filters
	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id <> Parent and Id <> 0;

	select [!$System!] = null,
		[!Hierarchies.Group!Filter] = @Group
end
go
-------------------------------------------------
create or alter procedure doc.[Price.Expand]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Group bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Items!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[Items!TGroup!Items] = null,
		[HasSubItems!!HasChildren] = case when exists(select 1 from cat.ItemTree c where c.Void=0 and c.Parent=a.Id) then 1 else 0 end,
		Icon = N'folder-outline'
	from cat.ItemTree a where Parent = @Id and Void=0;
end
go
-------------------------------------------------
create or alter procedure doc.[Price.Prices]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null, -- GroupId
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null,
@Date date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';

	declare @items table(rowno int identity(1, 1), id bigint, unit bigint, rowcnt int);
	--@Id = ite.Parent or 
	insert into @items(id, unit, rowcnt)
	select i.Id, i.Unit,
		count(*) over()
	from cat.Items i
		inner join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
		left join cat.ItemTreeElems ite on i.TenantId = ite.TenantId and i.Id = ite.Item
	where i.TenantId = @TenantId and i.Void = 0 and ir.HasPrice = 1
		and (@Id = -1 or @Id = ite.Parent or (@Id < 0 and i.Id not in (
			select Item from cat.ItemTreeElems intbl where intbl.TenantId = @TenantId and intbl.[Root] = -@Id /*hack:negative*/
		)))
		and (@fr is null or i.[Name] like @fr or i.Memo like @fr or Article like @fr or Barcode like @fr)
	group by i.Id, i.Unit, i.[Name], i.Article, i.Memo, i.[Role], i.Parent
	order by isnull(i.Parent, i.Id), i.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Prices!TPriceItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode, i.IsVariant,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short, ParentItemId = i.Parent,
		[Values!TPriceValue!Array] = null,
		[!!RowCount]  = t.rowcnt
	from @items t inner join cat.Items i on i.TenantId = @TenantId and i.Id = t.id
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	order by t.rowno;

	with TP as (
		select p.Item, p.PriceKind, [Date] = max(p.[Date])
		from doc.Prices p inner join @items t on p.TenantId = @TenantId and p.Item = t.id and 
			p.[Date] <= @Date
		group by p.Item, p.PriceKind
	)
	select [!TPriceValue!Array] = null, p.Price, p.PriceKind, [Date] = TP.[Date], [!TPriceItem.Values!ParentId] = TP.Item
	from doc.Prices p inner join TP on p.TenantId = @TenantId and p.Item = TP.Item 
		and p.PriceKind = TP.PriceKind and TP.[Date] = p.[Date];

	-- system data
	select [!$System!] = null,
		[!Prices!Offset] = @Offset, [!Prices!PageSize] = @PageSize, 
		[!Prices!SortOrder] = @Order, [!Prices!SortDir] = @Dir,
		[!Prices.Fragment!Filter] = @Fragment, [!Prices.Date!Filter] = @Date;
end
go
-------------------------------------------------
create or alter procedure doc.[Price.Set]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@PriceKind bigint,
@Date date,
@Value float
as
begin
	set nocount on;
	set transaction isolation level read committed;

	--TODO: Price.Currency

	merge doc.Prices as t
	using (select Item = @Id, PriceKind = @PriceKind, [Date] = @Date, [Price] = @Value) as s
	on t.TenantId = @TenantId and t.Item = s.Item and t.PriceKind = s.PriceKind and t.[Date] = s.[Date]
	when matched then update set
		t.Price = s.[Price]
	when not matched by target then insert
		(TenantId, Item, PriceKind, [Date], Price, Currency) values
		(@TenantId, Item, PriceKind, [Date], Price, 980);
end
go
-------------------------------------------------
create or alter procedure doc.[Price.Items.Get]
@TenantId int = 1,
@UserId bigint,
@Items nvarchar(1024),
@PriceKind bigint,
@Date date,
@CheckRems bit = 0,
@Wh bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @elems a2sys.[Id.TableType];
	insert into @elems (Id) 
		select [value] from string_split(@Items, N',');
	with TP as (
		select p.Item, [Date] = max(p.[Date])
		from doc.Prices p inner join @elems t on p.TenantId = @TenantId and p.Item = t.Id 
			and p.[Date] <= @Date and p.PriceKind = @PriceKind
		group by p.Item
	)
	select [Prices!TPrice!Array] = null, p.Item, p.Price
	from doc.Prices p inner join TP on p.TenantId = @TenantId and p.Item = TP.Item 
		and p.PriceKind = @PriceKind and TP.[Date] = p.[Date];

	select [Rems!TRem!Array] = null, r.Item, r.Rem, r.[Role]
	from doc.fn_getItemsRems(@CheckRems, @TenantId, @elems, @Date, @Wh) r;
end
go
-------------------------------------------------
create or alter function doc.fn_PriceGet(@TenantId int, @Item bigint, @PriceKind bigint, @Date date)
returns float
as
begin
	declare @val float;
	select @val = p.Price 
	from doc.Prices p where p.[Date] <= @Date and PriceKind = @PriceKind and p.Item = @Item
	return @val;
end
go

-- Lead
drop procedure if exists crm.[Lead.Maps];
drop type if exists crm.[Lead.Index.TableType]
go
-------------------------------------------------
create type crm.[Lead.Index.TableType] as table
(
	rowno int identity(1, 1), 
	id bigint, 
	agent bigint,
	contact bigint,
	currency bigint,
	rowcnt int
);
go
-------------------------------------------------
create or alter procedure crm.[Lead.Maps]
@TenantId int = 1,
@Elems crm.[Lead.Index.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	-- maps
	with T as (select agent from @Elems where agent is not null group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with T as (select contact from @Elems where contact is not null group by contact)
	select [!TContact!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Contacts c 
		inner join T t on c.TenantId = @TenantId and c.Id = contact;

	select [Stages!TStage!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color, Kind
	from crm.LeadStages 
	where TenantId = @TenantId and Void = 0 order by [Order];
end
go
-------------------------------------------------
create or alter procedure crm.[Lead.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'desc',
@Fragment nvarchar(255) = null,
@Tags nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';

	declare @leads crm.[Lead.Index.TableType];

	declare @ftags table(id bigint);
	insert into @ftags(id) select TRY_CAST([value] as bigint) from STRING_SPLIT(@Tags, N'-');

	insert into @leads(id, agent, contact, currency, rowcnt)
	select ld.Id, ld.Agent, ld.Contact, ld.Currency,
		count(*) over()
	from crm.Leads ld
	where ld.TenantId = @TenantId and ld.Void = 0
		and (@fr is null or ld.[Name] like @fr or ld.Memo like @fr)
		and (@Tags is null or exists(
				select 1 from @ftags f inner join crm.TagsLead tl on tl.TenantId = ld.TenantId and tl.[Lead] = ld.Id and f.id = tl.Tag and tl.TenantId = @TenantId
			)
		)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'date' then ld.[UtcDateCreated]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then ld.[Name]
				when N'memo' then ld.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order 
				when N'date' then ld.[UtcDateCreated]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then ld.[Name]
				when N'memo' then ld.[Memo]
			end
		end desc,
		ld.Id desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Leads!TLead!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Memo],
		[Agent!TAgent!RefId] = c.Agent, [Contact!TContact!RefId] = c.Contact, [Stage!TStage!RefId] = c.Stage,
		c.Amount, [Currency!TCurrency!RefId] = c.Currency,
		[DateCreated!!Utc] = c.UtcDateCreated,
		[Tags!TTag!Array] = null,
		[!!RowCount] = t.rowcnt
	from @leads t inner join 
		crm.Leads c on c.TenantId = @TenantId and c.Id = t.id
	order by t.rowno;


	-- maps
	exec crm.[Lead.Maps] @TenantId, @leads;

	-- tags
	select [!TTag!Array] = null, [Id!!Id] = tg.Id, [Name!!Name] = tg.[Name], tg.Color,
		[!TLead.Tags!ParentId] = tl.[Lead]
	from crm.TagsLead tl inner join cat.Tags tg on tl.TenantId = tg.TenantId and tl.Tag = tg.Id
		inner join @leads t on t.id = tl.[Lead] and tl.TenantId = @TenantId
	where tl.TenantId = @TenantId and tg.TenantId = @TenantId
	order by tg.Id;

	exec cat.[Tag.For] @TenantId =@TenantId, @UserId = @UserId, @For = N'Lead';

	select [!$System!] = null, [!Leads!Offset] = @Offset, [!Leads!PageSize] = @PageSize, 
		[!Leads!SortOrder] = @Order, [!Leads!SortDir] = @Dir,
		[!Leads.Fragment!Filter] = @Fragment, [!Leads.Tags!Filter] = @Tags;
end
go
-------------------------------------------------
create or alter procedure crm.[Lead.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Lead!TLead!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo,
		[Agent!TAgent!RefId] = c.Agent, [Contact!TContact!RefId] = c.Contact, [Stage!TStage!RefId] = c.Stage,
		c.Amount, [Currency!TCurrency!RefId] = c.Currency,
		[Tags!TTag!Array] = null,
		[DateCreated!!Utc] = c.UtcDateCreated
	from crm.Leads c
	where c.TenantId = @TenantId and c.Id = @Id;

	declare @leads crm.[Lead.Index.TableType];
	insert into @leads(agent, contact, currency) 
	select Agent, Contact, Currency 
	from crm.Leads where TenantId = @TenantId and Id = @Id;

	-- maps
	exec crm.[Lead.Maps] @TenantId, @leads;

	select [!TTag!Array] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color,
		[!TLead.Tags!ParentId] = tl.[Lead]
	from crm.TagsLead tl 
		inner join cat.Tags t on tl.TenantId = t.TenantId and tl.Tag = t.Id
	where tl.TenantId = @TenantId and tl.[Lead] = @Id;

	exec cat.[Tag.For] @TenantId =@TenantId, @UserId = @UserId, @For = N'Lead';
end
go
-------------------------------------------------
drop procedure if exists crm.[Lead.Metadata];
drop procedure if exists crm.[Lead.Update];
drop type if exists crm.[Lead.TableType];
go
-------------------------------------------------
create type crm.[Lead.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	Memo nvarchar(255),
	Contact bigint,
	Agent bigint,
	Amount money,
	Currency bigint,
	Stage bigint
)
go
------------------------------------------------
create or alter procedure crm.[Lead.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Lead crm.[Lead.TableType];
	declare @Tag a2sys.[Id.TableType];
	select [Lead!Lead!Metadata] = null, * from @Lead;
	select [Tags!Lead.Tags!Metadata] = null, * from @Tag;
end
go
------------------------------------------------
create or alter procedure crm.[Lead.Update]
@TenantId int = 1,
@UserId bigint,
@Lead crm.[Lead.TableType] readonly,
@Tags a2sys.[Id.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge crm.Leads as t
	using @Lead as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.Stage = s.Stage,
		t.Contact = s.Contact,
		t.Agent = s.Agent,
		t.Amount = s.Amount,
		t.Currency = s.Currency,
		t.UtcDateModified = getutcdate(),
		t.UserModified = @UserId
	when not matched by target then insert
		(TenantId, [Name], Memo, Stage, Contact, Agent, Amount, Currency, 
			UserCreated, UserModified, UtcDateModified) values
		(@TenantId, s.[Name], s.Memo, s.Stage, s.Contact, s.Agent, s.Amount, s.Currency,
		    @UserId, @UserId, getutcdate())
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	with TT as (
		select * from crm.TagsLead where TenantId = @TenantId and [Lead] = @id
	)
	merge TT as t
	using @Tags as s
	on t.TenantId = @TenantId and t.Tag = s.Id and t.[Lead] = @id
	when not matched by target then insert
		(TenantId,  [Lead], Tag) values
		(@TenantId, @id, s.Id)
	when not matched by source and t.[Lead] = @id and t.TenantId = @TenantId
	then delete;

	exec crm.[Lead.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

-------------------------------------------------
create or alter procedure crm.[Lead.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update crm.Leads set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

-------------------------------------------------
create or alter procedure crm.[Lead.Fetch]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	set @Company = nullif(@Company, 0);
	set @Agent = nullif(@Agent, 0);

	declare @cnts crm.[Lead.Index.TableType];

	/*
	insert into @cnts(id, agent, comp, pkind, kind)
	select top(100) c.Id, c.Agent, c.Company, c.PriceKind, c.Kind
	from crm.Leads c
	where c.TenantId = @TenantId and c.Void = 0
		and (@Agent is null or c.Agent = @Agent)
		and (@Company is null or c.Company = @Company)
		and (c.[Name] like @fr or c.[SNo] like @fr or c.Memo like @fr);

	select [Leads!TLead!Array] = null, [Id!!Id] = c.Id, c.[Date], [Name!!Name] = c.[Name], c.[Memo], c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company,
		[PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TLeadKind!RefId] = c.Kind
	from @cnts t inner join 
		crm.Leads c on c.TenantId = @TenantId and c.Id = t.id;
	*/
	-- maps
	exec crm.[Lead.Maps] @TenantId, @cnts;

end
go

/* TASK.Partial */
-------------------------------------------------
create or alter procedure app.[Task.Partial.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@LinkType nvarchar(64),
@LinkUrl nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Tasks!TTask!Array] = null, [Id!!Id] = t.Id, t.[Text], t.Notice, [DateCreated!!Utc] = t.UtcDateComplete,
		[State!TState!RefId] = t.[State], [Assignee!TUser!RefId] = t.Assignee
	from app.Tasks t 
	where t.TenantId = @TenantId and Link = @Id and LinkType = @LinkType
	order by t.UtcDateCreated desc;

	select [!TState!Map] = null, [Id!!Id] = ts.Id, [Name!!Name] = [Name], Color
	from app.TaskStates ts
	where ts.TenantId = @TenantId and ts.Void = 0
	order by ts.[Order];

	select [Params!TParam!Object] = null, LinkType = @LinkType, LinkId = @Id, LinkUrl = @LinkUrl
end
go


-------------------------------------------------
create or alter procedure app.[Task.Partial.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@LinkId bigint = null,
@LinkType nvarchar(64) = null,
@LinkUrl nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Task!TTask!MainObject] = null, [Id!!Id] = t.Id, t.[Text], [Assignee!TUser!RefId] = t.Assignee,
		[State!TState!RefId] = t.[State], t.Notice, [Project!TProject!RefId] = t.Project,
		LinkId = Link, LinkType, LinkUrl, [DateCreated!!Utc] = t.UtcDateComplete
	from app.Tasks t 
	where t.TenantId = @TenantId and Id = @Id;

	select [Params!TParam!Object] = null, LinkId = @LinkId, LinkType = @LinkType, LinkUrl = @LinkUrl;

	select [States!TState!Map] = null, [Id!!Id] = ts.Id, [Name!!Name] = [Name], Color
	from app.TaskStates ts
	where ts.TenantId = @TenantId and ts.Void = 0
	order by ts.[Order];
end
go
-------------------------------------------------
drop procedure if exists app.[Task.Partial.Metadata];
drop procedure if exists app.[Task.Partial.Update];
drop type if exists app.[Task.TableType];
go
-------------------------------------------------
create type app.[Task.TableType] as table
(
	Id bigint,
	[Text] nvarchar(255),
	Notice nvarchar(255),
	[State] bigint,
	LinkId bigint,
    LinkType nvarchar(64),
    LinkUrl nvarchar(255)
)
go
-------------------------------------------------
create or alter procedure app.[Task.Partial.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Task app.[Task.TableType];
	select [Task!Task!Metadata] = null, * from @Task;
end
go
-------------------------------------------------
create or alter procedure app.[Task.Partial.Update]
@TenantId int = 1,
@UserId bigint,
@Task app.[Task.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge app.Tasks as t
	using @Task as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Text] =  s.[Text],
		t.[Notice] = s.[Notice],
		t.Void = 0
	when not matched by target then insert
		(TenantId, [State], Link, LinkType, LinkUrl, [Text], [Notice]) values
		(@TenantId, s.[State], s.LinkId, s.LinkType, s.LinkUrl, s.[Text], [Notice])
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec app.[Task.Partial.Load] @UserId = @UserId, @Id = @id;
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
	declare @comp bigint = nullif(@Company, -1);
	declare @warh bigint = nullif(@Warehouse, -1);


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
	from jrn.Journal where TenantId = @TenantId and Account = @acc 
		and (@comp is null or Company = @comp)
		and (@warh is null or Warehouse = @warh)
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

	select [!TItem!Map] = null, i.* --[Id!!Id] = Id, [Name!!Name] = i.[Name], i.Article, i.Barcode
	from #tmp t inner join cat.view_Items i on i.[!TenantId] = @TenantId and t.Item = i.[Id!!Id]


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
	declare @comp bigint = nullif(@Company, -1);


	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	select IsRem = case when j.[Date] < @From then 1 else 0 end, 
		[Agent] = j.[Agent], Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when j.[Date] < @From then _SumDt else 0 end,
		CtStart = case when j.[Date] < @From then _SumCt else 0 end,
		DtSum = case when j.[Date] >= @From then _SumDt else 0 end,
		CtSum = case when j.[Date] >= @From then _SumCt else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and Account = @acc
		and [Date] < @end;

	with T as (
		select [Agent],
			DtStart = rep.fn_FoldSaldo(1, sum(DtStart), sum(CtStart)),
			CtStart = rep.fn_FoldSaldo(-1, sum(DtStart), sum(CtStart)),
			DtSum = sum(DtSum), 
			CtSum = sum(CtSum), 
			DtEnd = rep.fn_FoldSaldo(1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
			CtEnd = rep.fn_FoldSaldo(-1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
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
	where t.DtCt = 1 and t.IsRem = 0
	group by a.Code, t.Agent;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), [!TRepData.CtCross!ParentId] = t.Agent
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1 and t.IsRem = 0
	group by a.Code, t.Agent;

	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
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
	declare @comp bigint = nullif(@Company, -1);

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @start money;
	select @start = sum(j.[Sum] * j.DtCt)
	from jrn.Journal j where TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and Account = @acc and [Date] < @From;
	set @start = isnull(@start, 0);
	
	select [Date] = j.[Date], Id=cast([Date] as int), Acc = j.Account, CorrAcc = j.CorrAccount,
		DtCt = j.DtCt, DtSum = j._SumDt, CtSum = j._SumCt
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and Account = @acc
		and [Date] >= @From and [Date] < @end;

	if @@rowcount = 0
	begin
		select [RepData!TRepData!Group] = null, [Id!!Id] = 0, [Date] = null, StartSum = @start,
			DtSum = null, CtSum = null, EndSum = @start, 
			[Date!!GroupMarker] = 1,
			[DtCross!TCross!CrossArray] = null,
			[CtCross!TCross!CrossArray] = null,
			[Items!TRepData!Items] = null;
	end
	else 
	begin
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
	end

	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @comp, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Account.Agent.Contract.Load]
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

	select [Agent] = j.[Agent], [Contract] = isnull(j.[Contract], 0), Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when DtCt =  1 and j.[Date] < @From then [Sum] else 0 end,
		CtStart = case when DtCt = -1 and j.[Date] < @From then [Sum] else 0 end,
		DtSum = case when DtCt = 1 and j.[Date] >= @From then [Sum] else 0 end,
		CtSum = case when DtCt = -1 and j.[Date] >= @From then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and Account = @acc
		and [Date] < @end;

	with T as (
		select [Agent], [Contract],
			DtStart = rep.fn_FoldSaldo(1, sum(DtStart), sum(CtStart)),
			CtStart = rep.fn_FoldSaldo(-1, sum(DtStart), sum(CtStart)),
			DtSum = sum(DtSum),
			CtSum = sum(CtSum),
			DtEnd =  rep.fn_FoldSaldo(1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
			CtEnd =  rep.fn_FoldSaldo(-1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
			GrpAgent = grouping([Agent]),
			GrpContract = grouping([Contract])
		from #tmp 
		group by rollup([Agent], [Contract])
	) select [RepData!TRepData!Group] = null, [Id!!Id] = rep.fn_MakeRepId2(Agent, [Contract]),
		AgentId = Agent, ContractId = [Contract],
		[Agent!TAgent!RefId] = Agent,
		[Contract!TContract!RefId] = isnull([Contract], 0),
		DtStart, CtStart,
		DtSum, CtSum,
		DtEnd, CtEnd,
		[AgentId!!GroupMarker] = GrpAgent,
		[ContractId!!GroupMarker] = GrpContract,
		[DtCross!TCross!CrossArray] = null,
		[CtCross!TCross!CrossArray] = null,
		[Items!TRepData!Items] = null
	from T
	order by GrpAgent desc, GrpContract desc;

	-- agents
	with TA as (select Agent from #tmp group by Agent) 
	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA t on a.TenantId = @TenantId and a.Id = t.Agent;

	-- contracts
	with TA as (select [Contract] from #tmp group by [Contract]) 
	select [!TContract!Map] = null, [Id!!Id] = Id, [Name!!Name] = c.[Name], c.SNo, c.[Date]
	from doc.Contracts c inner join TA t on c.TenantId = @TenantId and c.Id = t.[Contract];

	-- dt cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[DtSum]), 
		[!TRepData.DtCross!ParentId] = rep.fn_MakeRepId2(t.Agent, t.[Contract])
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = 1 and t.DtSum <> 0
	group by a.Code, t.[Contract], t.Agent;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), 
		[!TRepData.CtCross!ParentId] = rep.fn_MakeRepId2(t.Agent, t.[Contract])
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1 and t.CtSum <> 0
	group by a.Code, t.[Contract], t.Agent;

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
create or alter procedure rep.[Report.Turnover.Account.RespCenter.CostItem.Load]
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

	select [RespCenter] = isnull(j.[RespCenter], 0), [CostItem] = isnull(j.[CostItem], 0), Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when DtCt =  1 and j.[Date] < @From then [Sum] else 0 end,
		CtStart = case when DtCt = -1 and j.[Date] < @From then [Sum] else 0 end,
		DtSum = case when DtCt = 1 and j.[Date] >= @From then [Sum] else 0 end,
		CtSum = case when DtCt = -1 and j.[Date] >= @From then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and Account = @acc
		and [Date] < @end;

	with T as (
		select [RespCenter] = isnull(RespCenter, 0), [CostItem],
			DtStart = rep.fn_FoldSaldo(1, sum(DtStart), sum(CtStart)),
			CtStart = rep.fn_FoldSaldo(-1, sum(DtStart), sum(CtStart)),
			DtSum = sum(DtSum),
			CtSum = sum(CtSum),
			DtEnd =  rep.fn_FoldSaldo(1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
			CtEnd =  rep.fn_FoldSaldo(-1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
			GrpRespCenter = grouping([RespCenter]),
			GrpCostItem = grouping([CostItem])
		from #tmp 
		group by rollup([RespCenter], [CostItem])
	) select [RepData!TRepData!Group] = null, [Id!!Id] = rep.fn_MakeRepId2(RespCenter, [CostItem]),
		RespCenterId = RespCenter, CostItemId = [CostItem],
		[RespCenter!TRespCenter!RefId] = RespCenter,
		[CostItem!TCostItem!RefId] = isnull([CostItem], 0),
		DtStart, CtStart,
		DtSum, CtSum,
		DtEnd, CtEnd,
		[RespCenterId!!GroupMarker] = GrpRespCenter,
		[CostItemId!!GroupMarker] = GrpCostItem,
		[DtCross!TCross!CrossArray] = null,
		[CtCross!TCross!CrossArray] = null,
		[Items!TRepData!Items] = null
	from T
	order by GrpRespCenter desc, GrpCostItem desc;

	-- resp centers
	with TR as (select RespCenter from #tmp group by RespCenter) 
	select [!TRespCenter!Map] = null, [Id!!Id] = Id, [Name!!Name] = rc.[Name]
	from cat.RespCenters rc inner join TR t on rc.TenantId = @TenantId and rc.Id = t.RespCenter;

	-- cost items
	with TC as (select [CostItem] from #tmp group by [CostItem]) 
	select [!TCostItem!Map] = null, [Id!!Id] = Id, [Name!!Name] = c.[Name]
	from cat.CostItems c inner join TC t on c.TenantId = @TenantId and c.Id = t.[CostItem];

	-- dt cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[DtSum]), 
		[!TRepData.DtCross!ParentId] = rep.fn_MakeRepId2(t.RespCenter, t.[CostItem])
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = 1 and t.DtSum <> 0
	group by a.Code, t.[CostItem], t.RespCenter;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), 
		[!TRepData.CtCross!ParentId] = rep.fn_MakeRepId2(t.RespCenter, t.[CostItem])
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1 and t.CtSum <> 0
	group by a.Code, t.[CostItem], t.RespCenter;

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
	declare @comp bigint = nullif(@Company, -1);

	declare @plan bigint;
	select @plan = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @accs table(id int);

	insert into @accs(id)
	select Id
	from acc.Accounts a where TenantId = @TenantId and [Plan] = @plan 
		and IsFolder = 0 and (IsCash = 1 or IsBankAccount = 1)
	group by a.Id;

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
		where j.TenantId = @TenantId and j.[Date] < @end and (@comp is null or j.Company = @comp)
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

	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @plan;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Plan.ItemRems.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@Date date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	select @Company = isnull(@Company, Company)
		from usr.Defaults where TenantId = @TenantId and UserId = @UserId;
	declare @comp bigint = nullif(@Company, -1);

	declare @plan bigint;
	select @plan = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @accounts table(Id bigint);
	insert into @accounts(Id) 
		select Id from acc.Accounts where TenantId = @TenantId and [Plan] = @plan and Void = 0 and IsWarehouse = 1 and IsItem = 1;

	select Warehouse, Item,
		Qty = sum(Qty * DtCt)
	into #tmp
	from jrn.Journal 
	where  Account in (select Id from @accounts) and [Plan] = @plan and TenantId = @TenantId
		and [Date] <= @Date and (@comp is null or Company = @comp)
	group by Warehouse, Item

	select [RepData!TRepData!Array] = null, [Id!!Id] = Item,
		[Item!TItem!RefId] = t.Item, Rem = sum(t.Qty),
		[WhCross!TCross!CrossArray] = null
	from #tmp t
	group by Item
	order by Item;

	-- cross part
	select [!TCross!CrossArray] = null, [Wh!!Key] = isnull(t.Warehouse, 0), Rem = sum(t.Qty),
		[!TRepData.WhCross!ParentId] = t.Item
	from #tmp t
	group by Item, Warehouse;

	-- report
	select [Report!TReport!Object] = null,  [Id!!Id] = r.Id, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	-- maps
	with T as (select Item from #tmp group by Item)
	select [!TItem!Map] = null, i.*
	from cat.view_Items i inner join T on i.[!TenantId] = @TenantId and T.Item = i.[Id!!Id];

	with T as (select Warehouse from #tmp group by Warehouse)
		select [Warehouses!TWarehouse!Array] = null, [Id!!Id] = w.Id,
		[Key!!Key] = cast(w.Id as nvarchar(32)), [Name!!Name] = w.[Name],
		[!TReport.Warehouses!ParentId] = @Id
	from cat.Warehouses w inner join T on w.TenantId = @TenantId and T.Warehouse = w.Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @plan;

	-- system
	select [!$System!] = null, 
		[!RepData.Date!Filter] = @Date,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go

-- reports cash
------------------------------------------------
create or alter procedure rep.[Report.Cash.Turnover.Date.Document.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@Company bigint = -1,
@CashAccount bigint = -1,
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	declare @comp bigint = nullif(@Company, -1);
	declare @cashacc bigint = nullif(@CashAccount, -1);

	
	declare @start money;
	select @start = sum(j.[Sum] * j.InOut)
	from jrn.CashJournal j where TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and (@cashacc is null or j.CashAccount = @cashacc)
		and [Date] < @From;
	set @start = isnull(@start, 0);
	
	select [Date], Document, SumIn = sum(_SumIn), SumOut = sum(_SumOut),
		GrpDate = grouping([Date]), GrpDocument = grouping(Document)
	into #temp
	from jrn.CashJournal j
	where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and (@cashacc is null or j.CashAccount = @cashacc)
		and j.[Date] >= @From and j.[Date] < @end
	group by rollup(j.[Date], j.Document);

	if @@rowcount = 0
		select [RepData!TRepData!Group] = null, [Id!!Id] = 0, [Date] = null, SumStart = @start,
			SumIn = null, SumOut = null, SumEnd = @start, [Agent!TAgent!RefId] = null,
			[Date!!GroupMarker] = 1,
			[Document!!GroupMarker] = 1,
			[Items!TRepData!Items] = null;
	else 
	begin
		with T ([Date], Document, SumStart, SumIn, SumOut, SumEnd, GrpDate, GrpDocument)
		as
			(
				select [Date], Document,
					@start + coalesce(sum(SumIn - SumOut) over (
						partition by GrpDate, GrpDocument order by [Date] rows between unbounded preceding and 1 preceding
					), 0),
					SumIn, SumOut,
					@start + sum(SumIn - SumOut) over (
						partition by GrpDate, GrpDocument  order by [Date] rows between unbounded preceding and current row),
					GrpDate, GrpDocument
				from #temp
			)
		select [RepData!TRepData!Group] = null, [Id!!Id] = T.Document, T.[Date], T.Document,
			[No] = coalesce(d.SNo, cast(d.[No] as nvarchar(50))), [Agent!TAgent!RefId] = d.Agent,
			o.DocumentUrl, OperationName = o.[Name],
			SumStart, SumIn, SumOut, SumEnd, 
			[Date!!GroupMarker] = GrpDate, [Document!!GroupMarker] = GrpDocument,
			[Items!TRepData!Items] = null
		from T
			left join doc.Documents d on d.TenantId = @TenantId and d.Id = T.Document 
			left join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		order by GrpDate desc, GrpDocument desc, T.[Date], T.Document;

		with T as (select d.Agent from #temp t inner join doc.Documents d on d.TenantId = @TenantId and t.Document = d.Id group by Agent)
		select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
		from cat.Agents a inner join T on a.TenantId = @TenantId and a.Id = T.Agent;
    end
	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;


	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @comp, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!RepData.CashAccount.Id!Filter] = @cashacc, [!RepData.CashAccount.Name!Filter] = cat.fn_GetCashAccountName(@TenantId, @CashAccount)
end
go

-- reports settle
------------------------------------------------
create or alter procedure rep.[Report.Settle.Turnover.Date.Agent.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@Company bigint = -1,
@Agent bigint = -1,
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	declare @comp bigint = nullif(@Company, -1);
	declare @ag bigint = nullif(@Agent, -1);

	
	declare @start money;
	select @start = sum(j.[Sum] * j.IncDec)
	from jrn.SettleJournal j where TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and (@ag is null or j.Agent = @ag)
		and [Date] < @From;
	set @start = isnull(@start, 0);
	
	select [Date], Agent, SumInc = sum(_SumInc), SumDec = sum(_SumDec),
		GrpDate = grouping([Date]), GrpAgent = grouping(Agent)
	into #temp
	from jrn.SettleJournal j
	where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and (@ag is null or j.Agent = @ag)
		and j.[Date] >= @From and j.[Date] < @end
	group by rollup(j.[Date], j.Agent);

	if @@rowcount = 0
		select [RepData!TRepData!Group] = null, [Id!!Id] = 0, [Date] = null, SumStart = @start,
			SumInc = null, SumDec = null, SumEnd = @start, [Agent!TAgent!RefId] = null,
			[Date!!GroupMarker] = 1,
			[Agent!!GroupMarker] = 1,
			[Items!TRepData!Items] = null;
	else 
	begin
		with T ([Date], Agent, SumStart, SumInc, SumDec, SumEnd, GrpDate, GrpAgent)
		as
			(
				select [Date], Agent,
					@start + coalesce(sum(SumInc - SumDec) over (
						partition by GrpDate, GrpAgent order by [Date] rows between unbounded preceding and 1 preceding
					), 0),
					SumInc, SumDec,
					@start + sum(SumInc - SumDec) over (
						partition by GrpDate, GrpAgent order by [Date] rows between unbounded preceding and current row),
					GrpDate, GrpAgent
				from #temp
			)
		select [RepData!TRepData!Group] = null, [Id!!Id] = T.Agent, T.[Date],
			[Agent!TAgent!RefId] = T.Agent,
			SumStart, SumInc, SumDec, SumEnd, 
			[Date!!GroupMarker] = GrpDate, [Agent!!GroupMarker] = GrpAgent,
			[Items!TRepData!Items] = null
		from T
		order by GrpDate desc, GrpAgent desc, T.[Date], T.Agent;

		with T as (select t.Agent from #temp t group by Agent)
		select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
		from cat.Agents a inner join T on a.TenantId = @TenantId and a.Id = T.Agent;
    end
	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;


	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @comp, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!RepData.Agent.Id!Filter] = @ag, [!RepData.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent)
end
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
	delete from doc.Prices where TenantId = @TenantId;
	delete from jrn.SupplierPrices where TenantId = @TenantId;
	delete from doc.DocDetails where TenantId = @TenantId;
	delete from doc.DocumentExtra where TenantId = @TenantId;
	delete from doc.Documents where TenantId = @TenantId;
	delete from cat.ItemRoleAccounts where TenantId = @TenantId;
	delete from cat.ItemTreeElems where TenantId = @TenantId;
	delete from cat.Items where TenantId = @TenantId;
	delete from cat.CashAccounts where TenantId = @TenantId;
	delete from cat.ItemRoles where TenantId = @TenantId;
	delete from doc.OpTrans where TenantId = @TenantId;
	delete from ui.OpMenuLinks where TenantId = @TenantId;
	delete from doc.OpPrintForms where TenantId = @TenantId;
	delete from doc.OperationLinks where TenantId = @TenantId;
	delete from doc.Operations where TenantId = @TenantId;
	delete from acc.AccKinds where TenantId = @TenantId;
	delete from app.Settings where TenantId = @TenantId;
	delete from acc.Accounts where TenantId = @TenantId;
	delete from doc.AutonumValues where TenantId = @TenantId;
	delete from doc.Autonums where TenantId = @TenantId;
	delete from cat.Units where TenantId = @TenantId;
	commit tran;


	insert into cat.ItemRoles (TenantId, [Uid], Id, Kind, [Name], Color, IsStock, HasPrice, ExType)
	values 
		(@TenantId, N'09E80BE6-D4CA-4639-AC10-206244F67313', 50, N'Item', N'Товар', N'green', 1, 1, null),
		(@TenantId, N'4BEF0104-0980-42B3-9918-0F260292BC23', 51, N'Item', N'Послуга', N'cyan', 0, 0, null),
		(@TenantId, N'E006A9CC-8F5B-447E-BA8A-0408911F4B40', 61, N'Money', N'Готівка', N'gold', 0, 0, N'C'),
		(@TenantId, N'44A9F6ED-6568-4E83-B9C1-53BD89552526', 62, N'Money', N'Безготівкові кошти', N'olive', 0, 0, N'B'),
		(@TenantId, N'73E79177-352F-4D0A-94EA-F43791421D99', 71, N'Expense', N'Адміністративні витрати', N'tan', 0, 0, N'B');

	insert into acc.Accounts(TenantId, Id, [Uid], [Plan], Parent, IsFolder, Code, [Name], 
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, IsContract, IsRespCenter, IsCostItem)
	values
		(@TenantId,  10, N'0A7FCDF2-7379-4EFE-B8A7-9B54D38188D0', null, null, 1, N'УПР', N'Управлінський', null, null, null, null, null, null, null, null),
		(@TenantId, 281, N'A43DAD4E-AE2E-451F-9D38-AF81BBBA00C3',   10,   10, 0, N'281', N'Товари',          1, 0, 1, 0, 0, 0, 0, 0),
		(@TenantId, 361, N'E12C5446-C9B1-43B4-A193-7825845CC924',   10,   10, 0, N'361', N'Покупці',         0, 1, 0, 0, 0, 1, 0, 0),
		(@TenantId, 631, N'B018D338-6184-413E-8475-6B49DE5D7E8E',   10,   10, 0, N'631', N'Постачальники',   0, 1, 0, 0, 0, 1, 0, 0),
		(@TenantId, 301, N'A37DCAB8-0F95-4912-87A8-07268798FC56',   10,   10, 0, N'301', N'Каса',            0, 0, 0, 0, 1, 0, 0, 0),
		(@TenantId, 311, N'13E8DE4C-2DF0-46E1-8EAD-8D2030BE20BB',   10,   10, 0, N'311', N'Рахунки в банку', 0, 0, 0, 1, 0, 0, 0, 0),
		(@TenantId, 702, N'CDB12B3F-CE26-4C33-8722-1E526167BA97',   10,   10, 0, N'702', N'Доходи',          0, 0, 0, 0, 0, 0, 1, 1),
		(@TenantId, 791, N'7F3D1E35-6D13-4E9A-89E1-B43EFE6CF8D2',   10,   10, 0, N'791', N'Фінрезультат',    0, 0, 0, 0, 0, 0, 1, 1),
		(@TenantId, 902, N'69CCD887-7104-4DDE-9843-3C11194BC673',   10,   10, 0, N'902', N'Собівартість',    0, 0, 0, 0, 0, 0, 1, 1),
		(@TenantId,  91, N'AB88082B-8444-49FF-8878-FAE9E943292E',   10,   10, 0, N'91',  N'Витрати',         0, 0, 0, 0, 0, 0, 1, 1);

	insert into acc.AccKinds(TenantId, [Uid], Id, [Name])
	values 
		(@TenantId, N'CE63659C-DE86-4B83-A763-FFFEDED04731', 70, N'Облік'),
		(@TenantId, N'6DB27876-CFFD-42F1-BF4F-47AFE1788AFC', 71, N'Дохід'),
		(@TenantId, N'3899198D-45AB-4AF0-9C58-44113169CF24', 72, N'Собівартість'),
		(@TenantId, N'8C8ED833-EF23-4A56-A0ED-208A5B804141', 73, N'Витрати'),
		(@TenantId, N'0A5BE1F1-0130-41C0-A713-6DA836F91506', 74, N'Фінансовий результат');

	insert into cat.ItemRoleAccounts (TenantId, Id, [Plan], [Role], Account, AccKind)
	values
		-- Товари
		(@TenantId, 10, 10, 50, 281, 70),
		(@TenantId, 11, 10, 50, 702, 71),
		(@TenantId, 12, 10, 50, 902, 72),
		-- Послуги
		(@TenantId, 20, 10, 51, 91,  70),
		(@TenantId, 21, 10, 51, 702, 71),
		-- Гроші
		(@TenantId, 31, 10, 61, 301, 70),
		(@TenantId, 32, 10, 62, 311, 70);

	insert into cat.Units (TenantId, Id, Short, CodeUA, [Name])
		select @TenantId, Id, Short, CodeUA, [Name] from cat.Units where TenantId = 0 and Id in (20, 27);

	insert into cat.Items(TenantId, Id, [Name], [Role], Unit) 
	values
		(@TenantId, 20, N'Товар №1', 50, 20),
		(@TenantId, 21, N'Послуга №1', 51, 27);

	insert into doc.Autonums(TenantId, Id, [Name], [Period], Pattern, [Uid]) 
	values
		(@TenantId, 20, N'Видаткові накладні', N'Y', N'{p}-{nnnnnn}', N'4F421AC2-AA7B-4C4F-8F7E-9D73E37C6295'),
		(@TenantId, 21, N'Платіжні доручення', N'Y', N'{p}-{nnnnnn}', N'90FB4D9E-E49C-42A4-9B26-7EBE9EDC3268'),
		(@TenantId, 22, N'Видаткові касові ордери', N'Y', N'{p}-{nnnnnn}', N'69C0105F-DA81-42FE-8C1E-9739007C7511');

	insert into doc.Operations (TenantId, Id, [Uid], [Name], [Form], DocumentUrl, Autonum) values
		(@TenantId, 100, N'137A9E57-D0A6-438E-B9A0-8B84272D5EB3', N'Придбання товарів/послуг',		 N'waybillin',  N'/document/purchase/waybillin', null),
		(@TenantId, 101, N'E3CB0D62-24AB-4FE3-BD68-DD2453F6B032', N'Оплата постачальнику (банк)',	 N'payout',     N'/document/money/payout', 21),
		(@TenantId, 102, N'80C9C85D-458E-445B-B35B-8177B40A5D41', N'Оплата постачальнику (готівка)', N'cashout',    N'/document/money/cashout', 22),
		(@TenantId, 103, N'D8DDB942-26AB-4402-9FD7-42E62BBCB57D', N'Продаж товарів/послуг',			 N'waybillout', N'/document/sales/waybillout', 20),
		(@TenantId, 104, N'C2C94B13-926C-41E5-9446-647B6C23B83E', N'Оплата від покупця (банк)',		 N'payin',      N'/document/money/payin', null),
		(@TenantId, 105, N'B31EB587-D242-4A96-8255-B824B1551963', N'Оплата від покупця (готівка)',	 N'cashin',     N'/document/money/cashin', null);

	insert into doc.OpTrans(TenantId, Id, Operation, RowNo, RowKind, [Plan], Dt, Ct, 
		[DtSum], DtRow, DtAccMode, DtAccKind,  [CtSum], [CtRow], CtAccMode, CtAccKind)
	values
		(@TenantId, 106, 104, 1, N'',        10,  311,  361,   null, null, null, null,   null, null, null, null),
		(@TenantId, 107, 102, 1, N'',        10,  631,  301,   null, null, null, null,   null, null, null, null),
		(@TenantId, 108, 101, 1, N'',        10,  631,  311,   null, null, null, null,   null, null, null, null),
		(@TenantId, 109, 100, 1, N'Stock',   10, null,  631,   null, N'R', N'R',   70,   null, null, null, null),
		(@TenantId, 110, 100, 2, N'Service', 10, null,  631,   null, N'R', N'R',   70,   null, null, null, null),
		(@TenantId, 111, 100, 3, N'Stock',   10, null,  631,   N'E', N'R', N'R',   70,   N'E', null, null, null),
		(@TenantId, 112, 105, 1, N'',        10,  301,  361,   null, null, null, null,   null, null, null, null),
		(@TenantId, 113, 103, 1, N'Stock',   10,  361,  702,   null, null, null, null,   null, N'R', N'R',   71),
		(@TenantId, 114, 103, 2, N'Stock',   10,  902, null,   N'S', N'R', N'R',   72,   N'S', N'R', N'R',   70),
		(@TenantId, 115, 103, 3, N'Service', 10,  361, null,   null, null, null, null,   null, N'R', N'R',   71);

	insert into ui.OpMenuLinks(TenantId, Operation, Menu) 
	values
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

	insert into doc.OperationLinks(TenantId, Id, Parent, Operation, Category, [Type]) 
	values 
		(@TenantId, 20, 100, 101, N'Оплата', N'BySum'),
		(@TenantId, 21, 100, 102, N'Оплата', N'BySum'),
		(@TenantId, 30, 103, 104, N'Оплата', N'BySum'),
		(@TenantId, 31, 103, 105, N'Оплата', N'BySum');

	insert into doc.OpPrintForms(TenantId, Operation, PrintForm) 
	values 
		(@TenantId, 100, N'invoice'),
		(@TenantId, 100, N'waybillout');

	if not exists(select * from cat.Companies where TenantId = @TenantId and Id = 10)
		insert into cat.Companies(TenantId, Id, [Name], AutonumPrefix) values (@TenantId, 10, N'Моє підприємство', N'МП');
	else if (select AutonumPrefix from cat.Companies where TenantId = @TenantId and Id = 10) is null
		update cat.Companies set AutonumPrefix = N'МП' where TenantId = @TenantId and Id = 10;

	if not exists(select * from cat.CashAccounts where TenantId = @TenantId and Id = 10 and IsCashAccount = 1)
		insert into cat.CashAccounts(TenantId, Id, Company, Currency, [Name], IsCashAccount, ItemRole) values (@TenantId, 10, 10, 980, N'Основна каса', 1, 61);
	if not exists(select * from cat.CashAccounts where TenantId = @TenantId and Id = 11 and IsCashAccount = 0)
		insert into cat.CashAccounts(TenantId, Id, Company, Currency, [Name], AccountNo, IsCashAccount, ItemRole) values (@TenantId, 11, 10, 980, N'Основний рахунок', N'<номер рахунку>', 0, 62);

	if not exists(select * from app.Settings)
		insert into app.Settings(TenantId, CheckRems, AccPlanRems) values (@TenantId, N'A', 10);
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


------------------------------------------------
create or alter procedure app.[Application.Delete]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from ui.OpMenuLinks where TenantId = @TenantId;
	delete from doc.OpPrintForms where TenantId = @TenantId;
	delete from doc.OperationLinks where TenantId = @TenantId;
	delete from doc.OpTrans where TenantId = @TenantId;
	delete from doc.AutonumValues where TenantId = @TenantId;
	delete from doc.Autonums where TenantId = @TenantId;
	delete from doc.Operations where TenantId = @TenantId;
	delete from cat.ItemRoleAccounts where TenantId = @TenantId;
end
go
------------------------------------------------
create or alter procedure app.[Application.Export.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Application!TApp!Object] = null, [!!Id] = 1,
		[AccKinds!AccKind!Array] = null, [Accounts!TAccount!Array] = null,
		[ItemRoles!TItemRole!Array] = null, [Operations!TOperation!Array] = null,
		[CostItems!TCostItem!Array] = null, [Autonums!TAutonum!Array] = null;

	select [!TAccKind!Array] = null, [Uid!!Id] = Uid, [Name], Memo,
		[!TApp.AccKinds!ParentId] = 1
	from acc.AccKinds where TenantId = @TenantId and Void = 0;

	with T(Id, Parent, [Plan], [Level])
	as (
		select a.Id, Parent, a.[Plan], 0 from
			acc.Accounts a where TenantId=@TenantId and a.Parent is null and a.[Plan] is null and Void=0
		union all 
		select a.Id, a.Parent, a.[Plan], T.[Level] + 1 
		from acc.Accounts a
			inner join T on T.Id = a.Parent and a.TenantId = @TenantId and a.Void = 0
		where a.TenantId = @TenantId
	)
	select [!TAccount!Array] = null, [Uid!!Id] = a.[Uid], [ParentAcc] = p.[Uid], [Plan] = pl.[Uid], T.[Level],
		a.[Name], a.Code, a.Memo,
		a.IsFolder, a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash, a.IsContract, a.IsRespCenter, a.IsCostItem,		
		[!TApp.Accounts!ParentId] = 1
	from acc.Accounts a inner join T on a.TenantId = @TenantId and a.Id = T.Id
		left join acc.Accounts p on a.TenantId = p.TenantId and p.Id = T.Parent
		left join acc.Accounts pl on a.TenantId = p.TenantId and pl.Id = T.[Plan]
	order by T.[Level];

	select [!TItemRole!Array] = null, [Id!!Id] = r.[Uid], r.Kind, r.[Name], r.Memo, 
		r.Color, r.HasPrice, r.IsStock, r.ExType, CostItem = ci.[Uid],
		[Accounts!TItemRoleAcc!Array] = null,
		[!TApp.ItemRoles!ParentId] = 1
	from cat.ItemRoles r 
		left join cat.CostItems ci on r.TenantId = ci.TenantId and r.CostItem = ci.Id
	where r.TenantId = @TenantId and r.Void = 0;

	select [!TItemRoleAcc!Array] = null, [Plan] = pl.[Uid], Account = acc.[Uid], AccKind = ak.[Uid],
		[!TItemRole.Accounts!ParentId] = ir.[Uid]
	from cat.ItemRoleAccounts ira
		inner join cat.ItemRoles ir on ira.TenantId = ir.TenantId and ira.[Role] = ir.[Id]
		inner join acc.Accounts pl on ira.TenantId = pl.TenantId and ira.[Plan] = pl.[Id]
		inner join acc.Accounts acc on ira.TenantId = acc.TenantId and ira.[Account] = acc.[Id]
		inner join acc.AccKinds ak on ira.TenantId = ak.TenantId and ira.[AccKind] = ak.[Id]
	where ira.TenantId = @TenantId and ir.Void = 0;

	select [!TCostItem!Array] = null, [Id!!Id] = ci.[Uid], ci.[Name], ci.[Memo], ci.IsFolder,
		ParentItem = cp.[Uid], [!TApp.CostItems!ParentId] = 1
	from cat.CostItems ci
		left join cat.CostItems cp on ci.TenantId = cp.TenantId and ci.Parent = cp.Id
	where ci.TenantId = @TenantId and ci.Void = 0;

	select [!TAutonum!Array] = null, [Uid!!Id] = an.[Uid], an.[Name], an.[Memo], an.[Period], an.Pattern,
		[!TApp.Autonums!ParentId] = 1
	from doc.Autonums an
	where an.TenantId = @TenantId and an.Void = 0;


	-- OPERATIONS
	select [!TOperation!Array] = null, [Id!!Id] = o.[Uid],
		o.[Name], o.[Memo], o.[Form], Autonum = an.[Uid], [Transactions!TOpTrans!Array] = null,
		[Store!TOpStore!Array] = null, [Cash!TOpCash!Array] = null, [Settle!TOpSettle!Array] = null,
		[PrintForms!TOpPrintForm!Array] = null, [Links!TOpLink!Array] = null,
		[MenuLinks!TOpMenuLink!Array] = null, 
		[!TApp.Operations!ParentId] = 1
	from doc.Operations o
		left join doc.Autonums an on o.TenantId = an.TenantId and o.Autonum = an.Id
	where o.TenantId = @TenantId and o.Void = 0;

	select [!TOpTrans!Array] = null, ot.RowNo, ot.RowKind, [Plan] = pl.[Uid], 
		Dt = dt.[Uid], Ct = ct.[Uid], DtAccMode, DtSum, DtRow, DtAccKind = dtack.[Uid],
		CtAccMode, CtSum, CtRow, CtAccKind =  ctack.[Uid],
		[!TOperation.Transactions!ParentId] = o.[Uid]
	from doc.OpTrans ot inner join doc.Operations o on ot.TenantId = o.TenantId and ot.Operation = o.Id
		left join acc.Accounts pl on ot.TenantId = pl.TenantId and ot.[Plan] = pl.Id
		left join acc.Accounts dt on ot.TenantId = dt.TenantId and ot.[Dt] = dt.Id
		left join acc.Accounts ct on ot.TenantId = ct.TenantId and ot.[Ct] = ct.Id
		left join acc.AccKinds dtack on ot.TenantId = dtack.TenantId and ot.DtAccKind = dtack.Id
		left join acc.AccKinds ctack on ot.TenantId = ctack.TenantId and ot.CtAccKind = ctack.Id
	where ot.TenantId = @TenantId and o.Void = 0;

	select [!TOpStore!Array] = null, ot.RowNo, ot.RowKind, IsIn, IsOut, Factor, 
		[!TOperation.Store!ParentId] = o.[Uid]
	from doc.OpStore ot inner join doc.Operations o on ot.TenantId = o.TenantId and ot.Operation = o.Id
	where ot.TenantId = @TenantId and o.Void = 0;

	select [!TOpCash!Array] = null, IsIn, IsOut, Factor, 
		[!TOperation.Cash!ParentId] = o.[Uid]
	from doc.OpCash ot inner join doc.Operations o on ot.TenantId = o.TenantId and ot.Operation = o.Id
	where ot.TenantId = @TenantId and o.Void = 0;

	select [!TOpSettle!Array] = null, IsInc, IsDec, Factor, 
		[!TOperation.Settle!ParentId] = o.[Uid]
	from doc.OpSettle ot inner join doc.Operations o on ot.TenantId = o.TenantId and ot.Operation = o.Id
	where ot.TenantId = @TenantId and o.Void = 0;

	select [!TOpPrintForm!Array] = null, [PrintForm] = opf.PrintForm,
		[!TOperation.PrintForms!ParentId] = o.[Uid]
	from doc.OpPrintForms opf 
		inner join doc.Operations o on opf.TenantId = o.TenantId and opf.Operation = o.Id
	where opf.TenantId = @TenantId and o.Void = 0;

	select [!TOpLink!Array] = null, ol.[Category], ol.[Type], ol.[Memo], Operation = o.[Uid],
		[!TOperation.Links!ParentId] = p.[Uid]
	from doc.OperationLinks ol
		inner join doc.Operations p on ol.TenantId = p.TenantId and ol.Parent = p.Id
		inner join doc.Operations o on ol.TenantId = o.TenantId and ol.Operation = o.Id
	where ol.TenantId = @TenantId and p.Void = 0;

	select [!TOpMenuLink!Array] = null, oml.Menu,
		[!TOperation.MenuLinks!ParentId] = o.[Uid]
	from ui.OpMenuLinks oml 
		inner join doc.Operations o on oml.TenantId = o.TenantId and oml.Operation = o.Id
	where oml.TenantId = @TenantId and o.Void = 0;
end
go
------------------------------------------------
drop procedure if exists app.[Application.Upload.Metadata];
drop procedure if exists app.[Application.Upload.Update];
drop type if exists app.[Application.AccKind.TableType];
drop type if exists app.[Application.Account.TableType];
drop type if exists app.[Application.CostItem.TableType];
drop type if exists app.[Application.ItemRole.TableType];
drop type if exists app.[Application.ItemRoleAcc.TableType];
drop type if exists app.[Application.Operation.TableType];
drop type if exists app.[Application.OpTrans.TableType];
drop type if exists app.[Application.OpStore.TableType];
drop type if exists app.[Application.OpCash.TableType];
drop type if exists app.[Application.OpSettle.TableType];
drop type if exists app.[Application.OpPrintForms.TableType];
drop type if exists app.[Application.OpLink.TableType];
drop type if exists app.[Application.OpMenuLink.TableType];
drop type if exists app.[Application.Autonum.TableType];
go
------------------------------------------------
create type app.[Application.AccKind.TableType] as table
(
	[Uid] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create type app.[Application.Account.TableType] as table
(
	[Uid] uniqueidentifier,
	[Plan] uniqueidentifier, 
	[ParentAcc] uniqueidentifier,
	[Level] int,
	IsFolder bit,
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
	IsCostItem bit
)
go
------------------------------------------------
create type app.[Application.ItemRole.TableType] as table
(
	[Id] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Kind] nvarchar(16),
	[Color] nvarchar(32),
	HasPrice bit,
	IsStock bit,
	ExType nchar(1),
	CostItem uniqueidentifier
)
go
------------------------------------------------
create type app.[Application.CostItem.TableType] as table
(
	[Id] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	IsFolder bit,
	ParentItem uniqueidentifier
)
go
------------------------------------------------
create type app.[Application.ItemRoleAcc.TableType] as table
(
	[ParentId] uniqueidentifier,
	[Plan] uniqueidentifier,
	[Account] uniqueidentifier,
	[AccKind] uniqueidentifier
)
go
------------------------------------------------
create type app.[Application.Operation.TableType] as table
(
	[Id] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Form] nvarchar(16),
	[Autonum] uniqueidentifier
);
go
------------------------------------------------
create type app.[Application.OpTrans.TableType] as table
(
	[ParentId] uniqueidentifier,
	RowNo int,
	[Plan] uniqueidentifier,
	[Dt] uniqueidentifier,
	[Ct] uniqueidentifier,
	RowKind nvarchar(16),
	DtAccMode nchar(1), 
	DtSum nchar(1), 
	DtRow nchar(1),
	DtAccKind uniqueidentifier,
	DtWarehouse nchar(1),
	CtAccMode nchar(1),
	CtSum nchar(1),
	CtRow nchar(1),
	CtAccKind uniqueidentifier
);
go
------------------------------------------------
create type app.[Application.OpStore.TableType] as table
(
	[ParentId] uniqueidentifier,
	RowNo int,
	RowKind nvarchar(16),
	IsIn bit,
	IsOut bit,
	Factor smallint
);
go
------------------------------------------------
create type app.[Application.OpCash.TableType] as table
(
	[ParentId] uniqueidentifier,
	IsIn bit,
	IsOut bit,
	Factor smallint
);
go
------------------------------------------------
create type app.[Application.OpSettle.TableType] as table
(
	[ParentId] uniqueidentifier,
	IsInc bit,
	IsDec bit,
	Factor smallint
);
go
------------------------------------------------
create type app.[Application.OpPrintForms.TableType] as table
(
	[ParentId] uniqueidentifier,
	PrintForm nvarchar(16)
)
go
------------------------------------------------
create type app.[Application.OpLink.TableType] as table
(
	[ParentId] uniqueidentifier,
	[Category] nvarchar(32),
	[Type] nvarchar(32),
	[Memo] nvarchar(255),
	Operation uniqueidentifier
);
go
------------------------------------------------
create type app.[Application.OpMenuLink.TableType] as table
(
	[ParentId] uniqueidentifier,
	Menu nvarchar(32)
);
go
------------------------------------------------
create type app.[Application.Autonum.TableType] as table
(
	[Uid] uniqueidentifier,
	[Name] nvarchar(255),
	[Period] nchar(1),
	Pattern nvarchar(255),
	[Memo] nvarchar(255)
);
go
------------------------------------------------
create or alter procedure app.[Application.Upload.Metadata]
as
begin
	set nocount on;

	declare @AccKinds app.[Application.AccKind.TableType];
	declare @Accounts app.[Application.Account.TableType];
	declare @CostItems app.[Application.CostItem.TableType];
	declare @ItemRoles app.[Application.ItemRole.TableType];
	declare @ItemRoleAcc app.[Application.ItemRoleAcc.TableType];
	declare @Operations app.[Application.Operation.TableType];
	declare @OpTrans app.[Application.OpTrans.TableType];
	declare @OpStore app.[Application.OpStore.TableType];
	declare @OpCash app.[Application.OpCash.TableType];
	declare @OpSettle app.[Application.OpSettle.TableType];
	declare @OpPrintForms app.[Application.OpPrintForms.TableType];
	declare @OpLinks app.[Application.OpLink.TableType];
	declare @OpMenuLinks app.[Application.OpMenuLink.TableType];
	declare @Autonums app.[Application.Autonum.TableType];

	select [AccKinds!Application.AccKinds!Metadata] = null, * from @AccKinds;
	select [Accounts!Application.Accounts!Metadata] = null, * from @Accounts;
	select [CostItems!Application.CostItems!Metadata] = null, * from @CostItems;
	select [ItemRoles!Application.ItemRoles!Metadata] = null, * from @ItemRoles;
	select [ItemRoleAcc!Application.ItemRoles.Accounts!Metadata] = null, * from @ItemRoleAcc;
	select [Operations!Application.Operations!Metadata] = null, * from @Operations;
	select [OpTrans!Application.Operations.Transactions!Metadata] = null, * from @OpTrans;
	select [OpStore!Application.Operations.Store!Metadata] = null, * from @OpStore;
	select [OpCash!Application.Operations.Cash!Metadata] = null, * from @OpCash;
	select [OpSettle!Application.Operations.Settle!Metadata] = null, * from @OpSettle;
	select [OpPrintForms!Application.Operations.PrintForms!Metadata] = null, * from @OpPrintForms;
	select [OpLinks!Application.Operations.Links!Metadata] = null, * from @OpLinks;
	select [OpMenuLinks!Application.Operations.MenuLinks!Metadata] = null, * from @OpMenuLinks;
	select [Autonums!Application.Autonums!Metadata] = null, * from @Autonums;
end
go
------------------------------------------------
create or alter procedure app.[Application.Upload.Update]
@TenantId int = 1,
@UserId bigint,
@AccKinds app.[Application.AccKind.TableType] readonly,
@Accounts app.[Application.Account.TableType] readonly,
@CostItems app.[Application.CostItem.TableType] readonly,
@ItemRoles app.[Application.ItemRole.TableType] readonly,
@ItemRoleAcc app.[Application.ItemRoleAcc.TableType] readonly,
@Operations app.[Application.Operation.TableType] readonly,
@OpTrans app.[Application.OpTrans.TableType] readonly,
@OpStore app.[Application.OpStore.TableType] readonly,
@OpCash app.[Application.OpCash.TableType] readonly,
@OpSettle app.[Application.OpSettle.TableType] readonly,
@OpPrintForms app.[Application.OpPrintForms.TableType] readonly,
@OpLinks app.[Application.OpLink.TableType] readonly,
@OpMenuLinks app.[Application.OpMenuLink.TableType] readonly,
@Autonums app.[Application.Autonum.TableType] readonly
as
begin
	set nocount on
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Autonums for xml auto);
	throw 60000, @xml, 0;
	*/

	-- account kinds
	merge acc.AccKinds as t
	using @AccKinds as s
	on t.TenantId = @TenantId and t.[Uid] = s.[Uid]
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.Void = 0
	when not matched by target then insert 
		(TenantId, [Uid], [Name], [Memo]) values
		(@TenantId, s.[Uid], s.[Name], s.[Memo]);

	-- accounts - step 1 - properties
	merge acc.Accounts as t 
	using @Accounts as s
	on t.TenantId = @TenantId and t.[Uid] = s.[Uid]
	when matched then update set
		t.Void = 0,
		t.[Name] = s.[Name],
		t.Code = s.Code,
		t.Memo = s.Memo,
		t.IsFolder = isnull(s.IsFolder, 0),
		t.IsItem = s.IsItem, IsAgent = s.IsAgent, t.IsWarehouse = s.IsWarehouse,
		t.IsBankAccount = s.IsBankAccount, t.IsCash = s.IsCash, t.IsContract = s.IsContract,
		t.IsRespCenter = s.IsRespCenter, t.IsCostItem = s.IsCostItem
	when not matched by target then insert
		(TenantId, [Uid], [Name], Code, [Memo], IsFolder, 
			IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, IsContract, IsRespCenter, IsCostItem) values
		(@TenantId, s.[Uid], s.[Name], s.Code, s.Memo, isnull(s.IsFolder, 0),
			s.IsItem, s.IsAgent, s.IsWarehouse, s.IsBankAccount, s.IsCash, s.IsContract, s.IsRespCenter, s.IsCostItem);

	-- accounts - step 2 - plan & parent
	with T as (
		select Id = a.Id, [Plan] = pl.Id, Parent = par.Id
		from @Accounts s inner join acc.Accounts a on a.TenantId = @TenantId and a.[Uid] = s.[Uid]
			left join acc.Accounts pl on pl.TenantId = @TenantId and pl.[Uid] = s.[Plan]
			left join acc.Accounts par on par.TenantId = @TenantId and par.[Uid] = s.[ParentAcc]
	)
	merge acc.Accounts as t 
	using T as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.Parent = s.Parent,
		t.[Plan] = s.[Plan];

	-- cost items - step 1
	merge cat.CostItems as t
	using @CostItems as s
	on t.TenantId = @TenantId and t.[Uid] = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.IsFolder = isnull(s.[IsFolder], 0)
	when not matched by target then insert
		(TenantId, [Uid], [Name], Memo, IsFolder) values
		(@TenantId, s.Id, s.[Name], s.Memo, isnull(s.IsFolder, 0));

	-- cost items - step 2
	with T as (
		select Id = t.Id, Parent = px.Id
		from @CostItems s inner join cat.CostItems t on t.TenantId = @TenantId and s.Id = t.[Uid]
		left join cat.CostItems px on px.TenantId = @TenantId and s.ParentItem = px.[Uid]
	)
	update cat.CostItems set Parent = T.Id
	from T inner join cat.CostItems ci on ci.TenantId = @TenantId and T.Id = ci.Id;

	-- item roles
	declare @itemrolestable table(id bigint, [uid] uniqueidentifier);
	merge cat.ItemRoles as t
	using (
		select s.Id, s.[Name], s.[Memo], s.Kind, s.Color, 
			s.HasPrice, s.IsStock, s.ExType, CostItem = ci.Id
		from @ItemRoles s 
		left join cat.CostItems ci on ci.TenantId=@TenantId and s.CostItem = ci.[Uid]
	) as s
	on t.TenantId = @TenantId and t.[Uid] = s.[Id]
	when matched then update set
		t.Void = 0,
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.Kind = s.Kind,
		t.Color = s.Color,
		t.HasPrice = s.HasPrice,
		t.IsStock = s.IsStock,
		t.ExType = s.ExType,
		t.CostItem = s.CostItem
	when not matched by target then insert
		(TenantId, [Uid], [Name], Memo, Kind, Color, HasPrice, IsStock, ExType) values
		(@TenantId, s.[Id], s.[Name], s.Memo, s.Kind, s.Color, s.HasPrice, s.IsStock, s.ExType)
	output inserted.Id, inserted.[Uid] into @itemrolestable(id, [uid]);


	delete from cat.ItemRoleAccounts where TenantId = @TenantId;
	with T as (
		select [Role] =  ir.id, Account = a.Id, AccKind = ak.Id, [Plan] = pl.Id
		from  @ItemRoleAcc s inner join @itemrolestable ir on s.ParentId = ir.[uid]
		inner join acc.Accounts pl on pl.TenantId = @TenantId and pl.[Uid] = s.[Plan]
		inner join acc.Accounts a on a.TenantId = @TenantId and a.[Uid] = s.Account
		inner join acc.AccKinds ak on ak.TenantId = @TenantId and ak.[Uid] = s.AccKind
	)
	insert into cat.ItemRoleAccounts(TenantId, [Role], [Plan], Account, AccKind)
	select @TenantId, [Role], [Plan], Account, AccKind from T;
	

	-- autnums
	merge doc.Autonums as t
	using @Autonums as s
	on t.TenantId = @TenantId and t.[Uid] = s.[Uid]
	when matched then update set
		t.[Name] = s.[Name],
		t.[Period] = s.[Period],
		t.Pattern = s.Pattern,
		t.[Memo] = s.[Memo],
		t.Void = 0
	when not matched by target then insert 
		(TenantId, [Uid], [Name], [Period], Pattern, [Memo]) values
		(@TenantId, s.[Uid], s.[Name], s.[Period], s.Pattern, s.[Memo]);

	-- operations
	declare @operationstable table(id bigint, [uid] uniqueidentifier);

	with OT as (
		select Id = o.Id, o.[Name], o.Memo, o.Form, Autonum = ans.Id
		from @Operations o left join @Autonums an on o.Autonum = an.[Uid]
		left join doc.Autonums ans on ans.TenantId = @TenantId and ans.[Uid] = an.[Uid]

	)
	merge doc.Operations as t
	using OT as s
	on t.TenantId = @TenantId and t.[Uid] = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Form] = s.[Form],
		t.[Autonum] = s.Autonum
	when not matched by target then insert
		(TenantId, [Uid], [Name], Memo, [Form], Autonum) values
		(@TenantId, s.Id, s.[Name], s.Memo, s.[Form], s.Autonum)
	output inserted.Id, inserted.[Uid] into @operationstable(id, [uid]);

	delete from doc.OpTrans where TenantId = @TenantId;
	with T as (
		select [Operation] =  op.id, RowKind = isnull(s.RowKind, N''), s.RowNo, [Plan] = pl.Id, [Dt] = dt.Id, [Ct] = ct.Id,
			DtAccKind = dtak.Id, CtAccKind = ctak.Id, s.DtAccMode, s.CtAccMode, s.DtRow, s.CtRow,
			s.DtSum, s.CtSum
		from  @OpTrans s inner join @operationstable op on s.ParentId = op.[uid]
			inner join acc.Accounts pl on pl.TenantId = @TenantId and pl.[Uid] = s.[Plan]
			left join acc.Accounts dt on dt.TenantId = @TenantId and dt.[Uid] = s.Dt
			left join acc.Accounts ct on ct.TenantId = @TenantId and ct.[Uid] = s.Ct
			left join acc.AccKinds dtak on dtak.TenantId = @TenantId and dtak.[Uid] = s.DtAccKind
			left join acc.AccKinds ctak on ctak.TenantId = @TenantId and ctak.[Uid] = s.CtAccKind
	)
	insert into doc.OpTrans(TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct, 
		DtAccMode, DtAccKind, DtSum, DtRow, CtAccMode, CtAccKind, CtRow, CtSum)
	select @TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct,
		DtAccMode, DtAccKind, DtSum, DtRow, CtAccMode, CtAccKind, CtRow, CtSum
	from T;

	delete from doc.OpStore where TenantId = @TenantId;
	with T as (
		select [Operation] =  op.id, RowKind = isnull(s.RowKind, N''), s.RowNo, IsIn = isnull(IsIn, 0), IsOut = isnull(IsOut, 0), Factor
		from  @OpStore s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into doc.OpStore(TenantId, Operation, RowNo, RowKind, IsIn, IsOut, Factor)
	select @TenantId, Operation, RowNo, RowKind, IsIn, IsOut, Factor
	from T;

	delete from doc.OpCash where TenantId = @TenantId;
	with T as (
		select [Operation] =  op.id, IsIn = isnull(IsIn, 0), IsOut = isnull(IsOut, 0), Factor
		from  @OpCash s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into doc.OpCash(TenantId, Operation, IsIn, IsOut, Factor)
	select @TenantId, Operation, IsIn, IsOut, Factor
	from T;

	delete from doc.OpSettle where TenantId = @TenantId;
	with T as (
		select [Operation] =  op.id, IsInc = isnull(IsInc, 0), IsDec = isnull(IsDec, 0), Factor
		from  @OpSettle s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into doc.OpSettle(TenantId, Operation, IsInc, IsDec, Factor)
	select @TenantId, Operation, IsInc, IsDec, Factor
	from T;


	delete from doc.OpPrintForms where TenantId = @TenantId;
	with T as (
		select [Operation] = op.id, s.PrintForm
		from @OpPrintForms s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into doc.OpPrintForms(TenantId, Operation, PrintForm)
	select @TenantId, Operation, PrintForm
	from T;

	delete from doc.OperationLinks where TenantId = @TenantId;
	with T as (
		select [Parent] = op.id, Operation = lo.Id, s.Category, s.[Type], s.Memo
		from @OpLinks s 
			inner join @operationstable op on s.ParentId = op.[uid]
			inner join doc.Operations lo on lo.TenantId = @TenantId and s.Operation = lo.[Uid]
	)
	insert into doc.OperationLinks(TenantId, Parent, Operation, Category, [Type], Memo)
	select @TenantId, Parent, Operation, Category, [Type], Memo
	from T;

	delete from ui.OpMenuLinks where TenantId = @TenantId;
	with T as (
		select [Operation] = op.id, s.Menu
		from @OpMenuLinks s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into ui.OpMenuLinks(TenantId, Operation, Menu)
	select @TenantId, Operation, Menu
	from T;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @CostItems for xml auto);
	throw 60000, @xml, 0;
	*/

	select [Result!TResult!Object] = null, [Success] = 1;
end
go


-- integration
------------------------------------------------
drop procedure if exists app.[Integration.Metadata];
drop procedure if exists app.[Integration.Update];
drop type if exists app.[Integration.TableType];
go
------------------------------------------------
create type app.[Integration.TableType] as table
(
	Id bigint,
	[Key] nvarchar(255),
	[Active] bit,
	[Name] nvarchar(255),
	ApiKey nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure app.[Integration.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Sources!TSource!Array] = null, [Id!!Id] = s.[Key],
		[Integrations!TIntegration!Array] = null
	from app.Integrations i
		inner join app.IntegrationSources s on i.Source = s.Id
	where TenantId = @TenantId
	group by s.[Key]
	order by s.[Key];

	select [!TIntegration!Array] = null, [Id!!Id] = i.Id, i.Active, i.[Name],
		s.Logo, SetupUrl, i.[Memo], [SourceName] = s.[Name],
		[!TSource.Integrations!ParentId] = s.[Key]
	from app.Integrations i
		inner join app.IntegrationSources s on i.Source = s.Id
	where TenantId = @TenantId
	order by i.Id;
end
go
------------------------------------------------
create or alter procedure app.[Integration.Browse.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Sources!TSource!Array] = null, Id = s.Id, [Key] = s.[Key], s.[Name], s.Logo,
		IntName = cast(null as nvarchar(255))
	from app.IntegrationSources s
	order by s.Id;
end
go
------------------------------------------------
create or alter procedure app.[Integration.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Integration!TIntegration!Object] = null, [Id!!Id] = i.Id,
		i.[Name], i.[Memo], i.Active, i.Source, i.ApiKey,
		SourceName = s.[Name], s.SetupUrl, s.Icon, s.[Key], s.Logo
	from app.Integrations i
		inner join app.IntegrationSources s on i.Source = s.Id
	where TenantId = @TenantId and i.Id = @Id;
end
go
------------------------------------------------
create or alter procedure app.[Integration.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Integration app.[Integration.TableType];
	select [Integration!Integration!Metadata] = null, * from @Integration;
end
go
------------------------------------------------
create or alter procedure app.[Integration.Update]
@TenantId int = 1,
@UserId bigint,
@Integration app.[Integration.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Integration for xml auto);
	throw 60000, @xml, 0;
	*/
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge app.Integrations as t
	using @Integration as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name],
		t.Active = s.Active, 
		t.ApiKey = s.ApiKey,
		t.[Memo] = s.[Memo]
	output $action, inserted.Id into @output (op, id);

	select @id = id from @output;

	exec app.[Integration.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

------------------------------------------------
create or alter procedure app.[Integration.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	delete from app.Integrations where TenantId = @TenantId and Id = @Id;
end
go

------------------------------------------------
create or alter procedure app.[Integration.Add]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Key nvarchar(16),
@Name nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @newid bigint;

	insert into app.Integrations(TenantId, [Source], [Key], [Name])
	output inserted.Id into @rtable(id)
	values (@TenantId, @Id, @Key, @Name);
	select @newid = id from @rtable;

	exec app.[Integration.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @newid;
end
go



-- SETTINGS.USER
------------------------------------------------
create or alter procedure appsec.[User.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Users!TUser!Array] = null, [Id!!Id] = u.Id, u.UserName, u.PersonName, u.PhoneNumber, 
		u.Memo, u.Email
	from appsec.Users u where Tenant = @TenantId and Void = 0 and Id <> 0;
end
go
------------------------------------------------
create or alter procedure appsec.[User.Create.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [User!TUser!Object] = null, [Id!!Id] = u.Id, u.UserName, u.PersonName, u.PhoneNumber, 
		u.Email,  u.Memo,
		[Password] = cast(null as nvarchar(255)), Confirm = cast(null as nvarchar(255))
	from appsec.Users u where 0 <> 0;
end
go
------------------------------------------------
create or alter procedure appsec.[User.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [User!TUser!Object] = null, [Id!!Id] = u.Id, u.UserName, u.PersonName, u.PhoneNumber, 
		u.Email,  u.Memo
	from appsec.Users u where u.Id = @Id;
end
go

create or alter procedure app.[Dashboard.SalesMonth.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null -- widget id
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Sales!TSale!Array] = null, [Id!!Id] = 0;
end
go
-- Notification
create or alter procedure app.[Navpane.Load]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Notify!TNotify!Object] = null, [Count] = count(*)
	from app.Notifications where TenantId = @TenantId and UserId = @UserId and Done = 0;
end
go
-------------------------------------------------
create or alter procedure app.[Notification.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Mode nvarchar(1) = N'U'
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @notes table(id bigint, rowcnt int, rowno int identity(1, 1));

	insert into @notes(id, rowcnt)
	select n.Id,
		count(*) over()
	from app.Notifications n
	where n.TenantId = @TenantId and n.UserId = @UserId
		and (@Mode = N'U' and Done = 0) or @Mode = 'A'
	order by UtcDateCreated desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Notifications!TNotify!Array] = null, [Id!!Id] = n.Id, n.[Text],
		n.Done, n.Link, n.LinkUrl, n.Icon, [DateCreated!!Utc] = n.UtcDateCreated,
		[!!RowCount] = t.rowcnt
	from @notes t inner join 
		app.Notifications n on n.TenantId = @TenantId and n.Id = t.id
	order by t.rowno;

	select [!$System!] = null, [!Notifications!Offset] = @Offset, [!Notifications!PageSize] = @PageSize, 
		[!Notifications.Mode!Filter] = @Mode;
end
go
-------------------------------------------------
create or alter procedure app.[Notification.Done]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update app.Notifications set Done = 1 where TenantId = @TenantId and Id = @Id;
end
go
-------------------------------------------------
create or alter procedure app.[Notification.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from app.Notifications where TenantId = @TenantId and Id = @Id;
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
(826, N'GBP', N'826', N'£', 100, N'Британський фунт стерлінгов'),
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
-- units
------------------------------------------------
begin
set nocount on;

declare @un table(Id bigint, Short nvarchar(8), [CodeUA] nchar(4), [Name] nvarchar(255));

insert into @un (Id, [Name], Short, CodeUA) values
(20, N'Штука',    N'шт',   N'2009'),
(21, N'Грам',     N'г',    N'0303'),
(22, N'Кілограм', N'кг',   N'0301'),
(23, N'Літр',     N'л',    N'0138'),
(24, N'Метр',     N'м',    N'0101'),
(25, N'Квадратний метр', N'м²',   N'0123'),
(26, N'Кубічний метр',   N'м³',   N'0134'),
(27, N'Година',   N'год',   N'0175');


merge cat.Units as t
using @un as s on t.Id = s.Id and t.TenantId = 0
when matched then update set
	t.[Short] = s.[Short],
	t.[Name] = s.[Name],
	t.[CodeUA] = s.[CodeUA]
when not matched by target then insert
	(TenantId, Id, Short, CodeUA, [Name]) values
	(0, s.Id, s.Short, s.CodeUA, s.[Name])
when not matched by source and t.TenantId = 0 then delete;
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
	if not exists(select * from cat.Currencies where Id=980 and TenantId = @TenantId)
		insert into cat.Currencies(TenantId, Id, Short, Alpha3, Number3, [Symbol], Denom, [Name]) 
		select @TenantId, Id, Short, Alpha3, Number3, Symbol, Denom, [Name]
			from cat.Currencies where TenantId = 0 and Id = 980;
	-- on create tenant all
	if not exists(select * from cat.ItemTree where TenantId = @TenantId)
		insert into cat.ItemTree(TenantId, Id, [Root], [Parent], [Name]) values (@TenantId, 0, 0, 0, N'ROOT');
end
go
-------------------------------------------------
create or alter procedure ini.[Rep.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	declare @rt table(Id nvarchar(16), [Order] int, [Name] nvarchar(255), UseAccount bit, [UsePlan] bit, UseStock bit, UseCash bit);
	insert into @rt (Id, [Order], [Name], UseAccount, [UsePlan], UseStock, UseCash) values
		(N'by.account', 10, N'@[By.Account]', 1, 0, 0, 0),
		(N'by.plan',    20, N'@[By.Plan]',    0, 1, 0, 0),
		(N'by.stock',   30, N'@[By.Stock]',   0, 0, 1, 0),
		(N'by.cash',    40, N'@[By.Cash]',    0, 0, 0, 0),
		(N'by.settle',  50, N'@[By.Settle]',  0, 0, 0, 0);
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

	-- FIX ERRORS
	delete from rep.Reports where [File] in (N'cash.rems');

	declare @rf table(Id nvarchar(16), [Order] int, [Type] nvarchar(16), [Url] nvarchar(255), [Name] nvarchar(255));
	insert into @rf (Id, [Type], [Order], [Url], [Name]) values
		-- acc
		(N'acc.date',      N'by.account',  1, N'/reports/account/rto_accdate',  N'Обороти рахунку (дата)'),
		(N'acc.agent',     N'by.account',  2, N'/reports/account/rto_accagent', N'Обороти рахунку (контрагент)'),
		(N'acc.agentcntr', N'by.account',  3, N'/reports/account/rto_accagentcontract', N'Обороти рахунку (контрагент + договір)'),
		(N'acc.respcost',  N'by.account',  4, N'/reports/account/rto_respcost', N'Обороти рахунку (центр відповідальності + стаття витрат)'),
		(N'acc.item',      N'by.account',  5, N'/reports/stock/rto_items',      N'Оборотно сальдова відомість (об''єкт обліку)'),
		-- plan
		(N'plan.turnover', N'by.plan', 1, N'/reports/plan/turnover',    N'Оборотно сальдова відомість'),
		(N'plan.money',    N'by.plan', 2, N'/reports/plan/cashflow',    N'Відомість по грошових коштах'),
		(N'plan.rems',     N'by.plan', 3, N'/reports/plan/itemrems',    N'Залишики на складах'),
		-- cash
		(N'cash.datedoc',  N'by.cash', 1, N'/reports/cash/rto_datedoc', N'Оборотно сальдова відомість (дата + документ)'),
		-- settle
		(N'settle.dateag',   N'by.settle', 1, N'/reports/settle/rto_dateag', N'Оборотно сальдова відомість (дата + контрагент)'),
		-- stock
		(N'stock.remswh',  N'by.stock', 1, N'/reports/stock/rems_wh', N'Залишки на складах');

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
	declare @df table(id nvarchar(16), [order] int, inout smallint, [url] nvarchar(255), 
		category nvarchar(255), [name] nvarchar(255), hasstate bit);
	insert into @df (id, inout, [order], hasstate, category, [url], [name]) values
		-- Sales
		(N'invoice',    null, 10, 1, N'@[Sales]', N'/document/sales', N'Замовлення клієнта'),
		(N'complcert',  null, 11, 0, N'@[Sales]', N'/document/sales', N'Акт виконаних робіт'),
		(N'waybillout', null, 12, 0, N'@[Sales]', N'/document/sales', N'Продаж товарів/послуг'),
		(N'retcust',    null, 13, 0, N'@[Sales]', N'/document/sales', N'Повернення від покупця'),
		-- Purchase
		(N'invoicein',  null, 20, 1, N'@[Purchases]', N'/document/purchase', N'Замовлення постачальнику'),
		(N'waybillin',  null, 21, 0, N'@[Purchases]', N'/document/purchase', N'Придбання товарів/послуг'),
		(N'retsuppl',   null, 22, 0, N'@[Purchases]', N'/document/purchase', N'Повернення постачальнику'),
		-- Invent
		(N'movebill',   null, 30, 0, N'@[KindStock]', N'/document/invent', N'Внутрішнє переміщення'),
		(N'inventbill', null, 31, 0, N'@[KindStock]', N'/document/invent', N'Інвентарізація'),
		(N'writeoff',   null, 32, 0, N'@[KindStock]', N'/document/invent', N'Акт списання'),
		(N'writeon',    null, 33, 0, N'@[KindStock]', N'/document/invent', N'Акт оприбуткування'),
		-- Money
		(N'payout',    -1,  40, 0, N'@[Money]', N'/document/money', N'Витрата безготівкових коштів'),
		(N'cashout',   -1,  41, 0, N'@[Money]', N'/document/money', N'Витрата готівки'),
		(N'payin',      1,  42, 0, N'@[Money]', N'/document/money', N'Надходження безготівкових коштів'),
		(N'cashin',     1,  43, 0, N'@[Money]', N'/document/money', N'Надходження готівки'),
		(N'cashmove', null, 44, 0, N'@[Money]', N'/document/money', N'Прерахування коштів'),
		(N'cashoff',  -1,   45, 0, N'@[Money]', N'/document/money', N'Списання коштів'),
		-- 
		(N'manufact',  null, 60, 0, N'@[Manufacturing]', N'/manufacturing/document', N'Виробничий акт-звіт');

	merge doc.Forms as t
	using @df as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order],
		t.InOut = s.inout,
		t.[Url] = s.[url],
		t.Category = s.category,
		t.HasState = s.hasstate
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], InOut, Category, [Url], HasState) values
		(@TenantId, s.id, s.[order], s.[name], inout, category, [url], hasstate)
	when not matched by source and t.TenantId = @TenantId then delete;

	-- docstates
	declare @st table(Id bigint, Form nvarchar(16), [Order] int, Kind nchar(1), [Name] nvarchar(255), Color nvarchar(32));
	insert into @st(Id, Form, [Order], Kind, [Name], Color) values
	(10, N'invoice', 10, N'I',  N'Новий', N'blue'),
	(20, N'invoice', 20, N'P',  N'В обробці', N'gold'),
	(30, N'invoice', 30, N'S',  N'Завершено', N'seagreen'),
	(40, N'invoice', 40, N'C',  N'Скасовано', N'red');

	merge doc.DocStates as t
	using @st as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.Kind = s.Kind,
		t.[Color] = s.[Color]
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], Form, Kind, Color) values
		(@TenantId, s.Id, s.[Order], s.[Name], s.Form, s.Kind, s.Color)
	when not matched by source and t.TenantId = @TenantId then delete;

	-- temp
	update doc.Operations set DocumentUrl = f.[Url] + N'/' + f.Id
	from doc.Operations o inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id

	-- form row kinds
	declare @rk table(Id nvarchar(16), [Order] int, Form nvarchar(16), [Name] nvarchar(255));
	insert into @rk([Form], [Order], Id, [Name]) values
	(N'waybillout', 1, N'Stock',   N'@[KindStock]'),
	(N'waybillout', 2, N'Service', N'@[KindServices]'),
	(N'waybillout', 3, N'All',     N'@[KindAllRows]'),
	(N'waybillin',  1, N'Stock',   N'@[KindStock]'),
	(N'waybillin',  2, N'Service', N'@[KindServices]'),
	(N'movebill',   1, N'Stock',   N'@[KindStock]'),
	(N'inventbill', 1, N'Stock',   N'@[KindStock]'),
	(N'writeoff',   1, N'Stock',   N'@[KindStock]'),
	(N'writeon',    1, N'Stock',   N'@[KindStock]'),
	(N'payin',      1, N'', N'Немає рядків'),
	(N'payout',     1, N'', N'Немає рядків'),
	(N'cashin',     1, N'', N'Немає рядків'),
	(N'cashout',    1, N'', N'Немає рядків'),
	(N'cashmove',   1, N'', N'Немає рядків'),
	(N'cashoff',    1, N'', N'Немає рядків'),
	(N'invoice',    1, N'Stock',   N'@[KindStock]'),
	(N'invoice',    2, N'Service', N'@[KindServices]'),
	(N'manufact',   1, N'Stock',   N'@[KindStock]'),
	(N'manufact',   2, N'Product', N'@[KindProd]');

	merge doc.FormRowKinds as t
	using @rk as s on t.Id = s.Id and t.Form = s.Form and t.TenantId = @TenantId
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Order] = s.[Order]
	when not matched by target then insert
		(TenantId, Id, [Form], [Name], [Order]) values
		(@TenantId, s.Id, s.[Form], s.[Name], s.[Order])
	when not matched by source and t.TenantId = @TenantId then delete;

	-- print forms
	declare @pf table(id nvarchar(16), [order] int, category nvarchar(255), [name] nvarchar(255), 
		[url] nvarchar(255), report nvarchar(255));
	insert into @pf (id, [order], category, [name], [url], [report]) values
		-- Sales
		(N'invoice',    1, N'@[Sales]', N'Замовлення клієнта', N'/document/print', N'invoice'),
		(N'waybillout', 2, N'@[Sales]', N'Видаткова накладна', N'/document/print', N'waybillout');

	merge doc.PrintForms as t
	using @pf as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order],
		t.Category = s.category,
		t.[Url] = s.[url],
		t.[Report] = s.[report]
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], Category, [Url], [Report]) values
		(@TenantId, s.id, s.[order], s.[name], category, [url], [report])
	when not matched by source and t.TenantId = @TenantId then delete;

end
go
-------------------------------------------------
-- Contracts
create or alter procedure ini.[Contract.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;
	-- contract kinds
	declare @ck table(Id nvarchar(16), [Order] int, [Name] nvarchar(255));
	insert into @ck(Id, [Order], [Name]) values
	(N'supplier', 1, N'@[ContractKind.Supplier]'),
	(N'customer', 2, N'@[ContractKind.Customer]'),
	(N'other',    9, N'@[ContractKind.Other]');

	merge doc.ContractKinds as t
	using @ck as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Order] = s.[Order]
	when not matched by target then insert
		(TenantId, Id, [Name], [Order]) values
		(@TenantId, s.Id, s.[Name], s.[Order])
	when not matched by source and t.TenantId = @TenantId then delete;
end
go
-------------------------------------------------
-- Operations
create or alter procedure ini.[Operation.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	-- TEMPORARY
	update doc.Operations set Kind = null where Kind like N'%.%';

	-- operation kinds
	declare @ok table(Id nvarchar(16),Factor smallint, [Order] int, [Name] nvarchar(255), Kind nvarchar(16), [Type] nchar(1));
	insert into @ok(Id, Factor, [Order], [Type], [Kind], [Name]) values
	(N'Order',         0, 1, N'B', N'Order',    N'@[OperationKind.Order]'),
	(N'Shipment',      1, 2, N'P', N'Shipment', N'@[OperationKind.Shipment]'),
	(N'RetShipment',  -1, 3, N'P', N'Shipment', N'@[OperationKind.Return]'),
	(N'Payment',       1, 4, N'P', N'Payment',  N'@[OperationKind.Payment]'),
	(N'RetPayment',   -1, 5, N'P', N'Payment',  N'@[OperationKind.RetPayment]');

	merge doc.OperationKinds as t
	using @ok as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set 
		t.Kind = s.Kind,
		t.LinkType = s.[Type],
		t.Factor = s.Factor,
		t.[Name] = s.[Name],
		t.[Order] = s.[Order]
	when not matched by target then insert
		(TenantId, Id, [Name], Kind, LinkType, Factor, [Order]) values
		(@TenantId, s.Id, s.[Name], s.Kind, s.[Type], s.Factor, s.[Order])
	when not matched by source and t.TenantId = @TenantId then delete;
end
go
-------------------------------------------------
-- Widgets
create or alter procedure ini.[Widgets.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	-- 1000 accounting - 1000,
	-- 2000 sales
	-- 3000 purchase
	-- 10000+ modules
	declare @widgets table(Kind nvarchar(16), Category nvarchar(64), Id bigint, rowSpan int, colSpan int, [Name] nvarchar(255), [Url] nvarchar(255), 
		Memo nvarchar(255), Icon nvarchar(32), Params nvarchar(1023));
	insert into @widgets (Id, Kind, Category, colSpan, rowSpan, [Name], [Url], Icon, Memo, Params) values
		(1000, N'Root',       N'@[Accounting]', 5, 3, N'Грошові кошти', N'/accounting/widgets/cashflow', N'chart-column', N'Діаграма руху грошових коштів', null),
		(1001, N'Root',       N'@[Sales]',      2, 1, N'Продажі',       N'/sales/widgets/salesmonth',    N'cart',         N'Продажі за місяць', null),
		--
		(2001, N'Accounting', N'@[Accounting]', 5, 3, N'Грошові кошти', N'/accounting/widgets/cashflow', N'chart-column', N'Діаграма руху грошових коштів', null);
		/*
		(1002, N'Root',       2, 1, N'Widget 2x1', N'/widgets/widget3/index', N'currency-uah', null, null);
		(N'Widget4', 2, 2, N'Widget 2x2', N'/widgets/widget4/index', null, null),
		(N'Widget5', 1, 1, N'Widget 1x1', N'/widgets/widget1/index', null, null),
		(N'Widget6', 2, 1, N'Widget 1x2', N'/widgets/widget2/index', null, null),
		(N'Widget7', 1, 2, N'Widget 2x1', N'/widgets/widget3/index', null, null),
		(N'Widget8', 2, 2, N'Widget 2x2', N'/widgets/widget4/index', null, null);
		*/
	merge app.Widgets as t
	using @widgets as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.rowSpan = s.rowSpan,
		t.colSpan = s.colSpan,
		t.[Url] = s.[Url],
		t.Memo = s.Memo,
		t.Icon = s.Icon,
		t.Kind = s.Kind,
		t.Category = s.Category,
		t.Params = s.Params
	when not matched by target then insert
		(TenantId, Id, Kind, Category, [Name], rowSpan, colSpan, [Url], Memo, Icon, Params) values
		(@TenantId, s.Id, s.Category, s.Kind, s.[Name], s.rowSpan, s.colSpan, s.[Url], s.Memo, s.Icon, s.Params);
end
go
-------------------------------------------------
-- Crm
create or alter procedure ini.[Crm.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;

	-- (I)nit, (P)rocess, [S]uccess, F(ail)
	declare @ls table(Kind nchar(1), Id bigint, [Order] int, [Name] nvarchar(255), Color nvarchar(32));
	insert into @ls (Kind, Id, [Order], [Name], [Color]) values
		(N'I', 10, 10, N'Новий', N'blue'),
		(N'P', 20, 20, N'В обробці', N'orange'),
		(N'S', 30, 30, N'Успіх', N'seagreen'),
		(N'F', 40, 40, N'Невдача', N'red');
	merge crm.LeadStages as t
	using @ls as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.Kind = s.Kind,
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.[Color] = s.[Color]
	when not matched by target then insert
		(TenantId, Id, Kind, [Name], [Order], [Color]) values
		(@TenantId, s.Id, s.Kind, s.[Name], s.[Order], s.[Color]);
end
go
-------------------------------------------------
-- App
create or alter procedure ini.[App.OnCreateTenant]
@TenantId int
as
begin
	set nocount on;
	declare @ts table(Id bigint, [Order] int, [Name] nvarchar(255), Color nvarchar(32));
	insert into @ts (Id, [Order], [Name], [Color]) values
		(10, 10, N'Нова', N'blue'),
		(20, 20, N'В обробці', N'orange'),
		(30, 30, N'Завершена', N'seagreen'),
		(40, 40, N'Скасована', N'red');
	merge app.TaskStates as t
	using @ts as s on t.Id = s.Id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.[Color] = s.[Color]
	when not matched by target then insert
		(TenantId, Id, [Name], [Order], [Color]) values
		(@TenantId, s.Id, s.[Name], s.[Order], s.[Color]);
end
go
------------------------------------------------
-- !CHECK startup_mt.sql!
exec ini.[Cat.OnCreateTenant] @TenantId = 1;
exec ini.[Forms.OnCreateTenant] @TenantId = 1;
exec ini.[Rep.OnCreateTenant] @TenantId = 1;
exec ini.[Widgets.OnCreateTenant] @TenantId = 1;
exec ini.[Contract.OnCreateTenant] @TenantId = 1;
exec ini.[Operation.OnCreateTenant] @TenantId = 1;
exec ini.[Crm.OnCreateTenant] @TenantId = 1;
exec ini.[App.OnCreateTenant] @TenantId = 1;
go


/*
flush
*/
------------------------------------------------
drop table if exists doc.OpJournalStore;
drop type if exists doc.[OpJournalStore.TableType];
drop sequence if exists doc.SQ_OpJournalStore;
go


