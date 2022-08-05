/*
version: 10.1.1021
generated: 05.08.2022 06:32:41
*/


/* SqlScripts/application.sql */

/*
version: 10.0.7779
generated: 01.08.2022 12:29:16
*/

set nocount on;
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'a2sys')
	exec sp_executesql N'create schema a2sys';
go
-----------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'Versions')
	create table a2sys.Versions
	(
		Module sysname not null constraint PK_Versions primary key,
		[Version] int null,
		[Title] nvarchar(255),
		[File] nvarchar(255)
	);
go
----------------------------------------------
if exists(select * from a2sys.Versions where [Module]=N'script:platform')
	update a2sys.Versions set [Version]=7779, [File]=N'a2v10platform.sql', Title=null where [Module]=N'script:platform';
else
	insert into a2sys.Versions([Module], [Version], [File], Title) values (N'script:platform', 7779, N'a2v10platform.sql', null);
go



/* a2v10platform.sql */

/*
Copyright © 2008-2021 Alex Kukhtin

Last updated : 27 jun 2021
module version : 7061
*/
------------------------------------------------
set nocount on;
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'a2sys')
begin
	exec sp_executesql N'create schema a2sys';
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'Versions')
begin
	create table a2sys.Versions
	(
		Module sysname not null constraint PK_Versions primary key,
		[Version] int null,
		[Title] nvarchar(255),
		[File] nvarchar(255)
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'Versions' and COLUMN_NAME=N'Title')
begin
	alter table a2sys.Versions add [Title] nvarchar(255) null;
	alter table a2sys.Versions add [File] nvarchar(255) null;
end
go
------------------------------------------------
if not exists(select * from a2sys.Versions where Module = N'std:system')
	insert into a2sys.Versions (Module, [Version]) values (N'std:system', 7061);
else
	update a2sys.Versions set [Version] = 7061 where Module = N'std:system';
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'SysParams')
begin
	create table a2sys.SysParams
	(
		Name sysname not null constraint PK_SysParams primary key,
		StringValue nvarchar(255) null,
		IntValue int null,
		DateValue datetime null
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'SysParams' and COLUMN_NAME=N'DateValue')
begin
	alter table a2sys.SysParams add DateValue datetime null;
end
go
------------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2sys.fn_toUtcDateTime') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2sys.fn_toUtcDateTime;
go
------------------------------------------------
create function a2sys.fn_toUtcDateTime(@date datetime)
returns datetime
as
begin
	declare @mins int;
	set @mins = datediff(minute,getdate(),getutcdate());
	return dateadd(minute, @mins, @date);
end
go
------------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2sys.fn_trimtime') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2sys.fn_trimtime;
go
------------------------------------------------
create function a2sys.fn_trimtime(@dt datetime)
returns datetime
as
begin
	declare @ret datetime;
	declare @f float;
	set @f = cast(@dt as float)
	declare @i int;
	set @i = cast(@f as int);
	set @ret = cast(@i as datetime);
	return @ret;
end
go
------------------------------------------------
if not exists (select * from sys.objects where object_id = object_id(N'a2sys.fn_getCurrentDate') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
exec sp_executesql N'
create function a2sys.fn_getCurrentDate() 
returns datetime 
as begin return getdate(); end';
go
------------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2sys.fn_trim') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2sys.fn_trim;
go
------------------------------------------------
create function a2sys.fn_trim(@value nvarchar(max))
returns nvarchar(max)
as
begin
	return ltrim(rtrim(@value));
end
go
------------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2sys.fn_string2table') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2sys.fn_string2table;
go
------------------------------------------------
create function a2sys.fn_string2table(@var nvarchar(max), @delim nchar(1))
	returns @ret table(VAL nvarchar(max))
as
begin
	select @var = @var + @delim; -- sure delim

	declare @pos int, @start int;
	declare @sub nvarchar(255);

	set @start = 1;
	set @pos   = charindex(@delim, @var, @start);

	while @pos <> 0
		begin
			set @sub = ltrim(rtrim(substring(@var, @start, @pos-@start)));

			if @sub <> N''
				insert into @ret(VAL) values (@sub);

			set @start = @pos + 1;
			set @pos   = charindex(@delim, @var, @start);
		end
	return;
end
go
------------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2sys.fn_string2table_count') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2sys.fn_string2table_count;
go
------------------------------------------------
create function a2sys.fn_string2table_count(@var nvarchar(max), @count int)
	returns @ret table(RowNo int, VAL nvarchar(max))
as
begin

	declare @start int;
	declare @RowNo int;
	declare @sub nvarchar(255);

	set @start = 1;
	set @RowNo = 1;

	while @start <= len(@var)
		begin
			set @sub = substring(@var, @start, @count);

			if @sub <> N''
				insert into @ret(RowNo, VAL) values (@RowNo, @sub);

			set @start = @start + @count;
			set @RowNo = @RowNo + 1;
		end
	return;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'AppFiles')
begin
create table a2sys.AppFiles (
	[Path] nvarchar(255) not null constraint PK_AppFiles primary key,
	Stream nvarchar(max) null,
	DateModified datetime constraint DF_AppFiles_DateModified default(a2sys.fn_getCurrentDate())
)	
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2sys' and DOMAIN_NAME=N'Id.TableType' and DATA_TYPE=N'table type')
begin
	create type a2sys.[Id.TableType]
	as table(
		Id bigint null
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2sys' and DOMAIN_NAME=N'GUID.TableType' and DATA_TYPE=N'table type')
begin
	create type a2sys.[GUID.TableType]
	as table(
		Id uniqueidentifier null
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2sys' and DOMAIN_NAME=N'NameValue.TableType' and DATA_TYPE=N'table type')
begin
	create type a2sys.[NameValue.TableType]
	as table(
		[Name] nvarchar(255),
		[Value] nvarchar(max)
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2sys' and DOMAIN_NAME=N'Kind.TableType' and DATA_TYPE=N'table type')
begin
	create type a2sys.[Kind.TableType]
	as table(
		Kind nchar(4) null
	);
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2sys' and ROUTINE_NAME=N'GetVersions')
	drop procedure a2sys.[GetVersions]
go
------------------------------------------------
create procedure a2sys.[GetVersions]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Module], [Version], [File], [Title] from a2sys.Versions;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2sys' and ROUTINE_NAME=N'SetVersion')
	drop procedure a2sys.[SetVersion]
go
------------------------------------------------
create procedure a2sys.[SetVersion]
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
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2sys' and ROUTINE_NAME=N'LoadApplicationFile')
	drop procedure [a2sys].[LoadApplicationFile]
go
------------------------------------------------
create procedure [a2sys].[LoadApplicationFile]
	@Path nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Path], Stream from a2sys.AppFiles where [Path] = @Path;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2sys' and ROUTINE_NAME=N'UploadApplicationFile')
	drop procedure [a2sys].[UploadApplicationFile]
go
------------------------------------------------
create procedure [a2sys].[UploadApplicationFile]
@Path nvarchar(255),
@Stream nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update a2sys.AppFiles set Stream = @Stream, DateModified = a2sys.fn_getCurrentDate() where [Path] = @Path;

	if @@rowcount = 0
		insert into a2sys.AppFiles([Path], Stream)
		values (@Path, @Stream);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'DbEvents')
begin
create table a2sys.DbEvents 
(
	[Id] uniqueidentifier not null constraint PK_DbEvents primary key
	constraint DF_DbEvents_Id default newid(),
	ItemId bigint,
	[Path] nvarchar(255),
	[Command] nvarchar(255),
	[Source] nvarchar(255),
	[State] nvarchar(32) constraint DF_DbEvents_State default N'Init',
	DateCreated datetime constraint DF_DbEvents_DateCreated default(a2sys.fn_getCurrentDate()),
	DateHold datetime,
	DateComplete datetime,
	[JsonParams] nvarchar(1024) sparse,
	ErrorMessage nvarchar(1024) sparse
)
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2sys' and TABLE_NAME=N'DbEvents' and COLUMN_NAME=N'Source')
begin
	alter table a2sys.DbEvents add [Source] nvarchar(255);
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2sys' and ROUTINE_NAME=N'DbEvent.Add')
	drop procedure a2sys.[DbEvent.Add]
go
------------------------------------------------
create procedure a2sys.[DbEvent.Add]
@ItemId bigint,
@Path nvarchar(255),
@Command nvarchar(255),
@Source nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	insert into a2sys.DbEvents(ItemId, [Path], Command, [Source]) values
		(@ItemId, @Path, @Command, @Source);
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2sys' and ROUTINE_NAME=N'DbEvent.Fetch')
	drop procedure a2sys.[DbEvent.Fetch]
go
------------------------------------------------
create procedure a2sys.[DbEvent.Fetch]
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(Id uniqueidentifier, ItemId bigint, [Path] nvarchar(255),
		[JsonParams] nvarchar(1024), Command nvarchar(255), [Source] nvarchar(255));

	update a2sys.DbEvents set [State] = N'Hold', DateHold = a2sys.fn_getCurrentDate()
	output inserted.Id, inserted.ItemId, inserted.[Path], inserted.Command, inserted.JsonParams, inserted.[Source]
	into @rtable(Id, ItemId, [Path], Command, JsonParams, [Source])
	where [State] = N'Init';

	select [Id], ItemId, [Path], Command, [Source], JsonParams from @rtable;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2sys' and ROUTINE_NAME=N'DbEvent.Error')
	drop procedure a2sys.[DbEvent.Error]
go
------------------------------------------------
create procedure a2sys.[DbEvent.Error]
@Id uniqueidentifier,
@ErrorMessage nvarchar(1024) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	update a2sys.[DbEvents] set [State]=N'Fail', 
		ErrorMessage = @ErrorMessage, DateComplete = a2sys.fn_getCurrentDate()
	where Id=@Id;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2sys' and ROUTINE_NAME=N'DbEvent.Complete')
	drop procedure a2sys.[DbEvent.Complete]
go
------------------------------------------------
create procedure a2sys.[DbEvent.Complete]
@Id uniqueidentifier
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	update a2sys.[DbEvents] set [State]=N'Complete', DateComplete = a2sys.fn_getCurrentDate()
	where Id=@Id;
end
go
------------------------------------------------
begin
	set nocount on;
	grant execute on schema ::a2sys to public;
end
go
------------------------------------------------
go


/*
------------------------------------------------
Copyright © 2008-2022 Alex Kukhtin

Last updated : 10 feb 2022
module version : 7770
*/
------------------------------------------------
exec a2sys.SetVersion N'std:security', 7770;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'a2security')
begin
	exec sp_executesql N'create schema a2security';
end
go
------------------------------------------------
-- a2security schema
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2security' and SEQUENCE_NAME=N'SQ_Tenants')
	create sequence a2security.SQ_Tenants as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants')
begin
	create table a2security.Tenants
	(
		Id	int not null constraint PK_Tenants primary key
			constraint DF_Tenants_PK default(next value for a2security.SQ_Tenants),
		[Admin] bigint null, -- admin user ID
		[Source] nvarchar(255) null,
		[TransactionCount] bigint not null constraint DF_Tenants_TransactionCount default(0),
		LastTransactionDate datetime null,
		DateCreated datetime not null constraint DF_Tenants_UtcDateCreated2 default(a2sys.fn_getCurrentDate()),
		TrialPeriodExpired datetime null,
		DataSize float null,
		[State] nvarchar(128) null,
		UserSince datetime null,
		LastPaymentDate datetime null,
		Balance money null,
		[Locale] nvarchar(32) not null constraint DF_Tenants_Locale default('uk-UA')
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'Locale')
	alter table a2security.Tenants add [Locale] nvarchar(32) not null constraint DF_Tenants_Locale default('uk-UA');
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Config')
begin
	create table a2security.Config
	(
		[Key] sysname not null constraint PK_Config primary key,
		[Value] nvarchar(255) not null,
	);
end
go
------------------------------------------------
if not exists (select * from sys.indexes where object_id = object_id(N'a2security.Tenants') and name = N'IX_Tenants_Admin')
	create index IX_Tenants_Admin on a2security.Tenants ([Admin]) include (Id);
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_Tenants_UtcDateCreated' and parent_object_id = object_id(N'a2security.Tenants'))
begin
	alter table a2security.Tenants drop constraint DF_Tenants_UtcDateCreated;
	alter table a2security.Tenants add constraint DF_Tenants_UtcDateCreated2 default(a2sys.fn_getCurrentDate()) for DateCreated with values;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'TransactionCount')
begin
	alter table a2security.Tenants add [TransactionCount] bigint not null constraint DF_Tenants_TransactionCount default(0);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'TrialPeriodExpired')
begin
	alter table a2security.Tenants add TrialPeriodExpired datetime null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'LastTransactionDate')
begin
	alter table a2security.Tenants add [LastTransactionDate] datetime null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'LastPaymentDate')
begin
	alter table a2security.Tenants add LastPaymentDate datetime null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'Balance')
begin
	alter table a2security.Tenants add Balance money null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'DataSize')
	alter table a2security.Tenants add DataSize float null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'State')
	alter table a2security.Tenants add [State] nvarchar(128) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Tenants' and COLUMN_NAME=N'UserSince')
	alter table a2security.Tenants add UserSince datetime null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2security' and SEQUENCE_NAME=N'SQ_Users')
	create sequence a2security.SQ_Users as bigint start with 100 increment by 1;
go
------------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2security.fn_GetCurrentSegment') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2security.fn_GetCurrentSegment;
go
------------------------------------------------
create function a2security.fn_GetCurrentSegment()
returns nvarchar(32)
as
begin
	declare @ret nvarchar(32);
	select @ret = [Value] from a2security.Config where [Key] = N'CurrentSegment';
	return @ret;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Modules')
begin
	create table a2security.Modules
	(
		[Id] nvarchar(16) not null constraint PK_Modules primary key,
		[Name] nvarchar(255) not null,
		Memo nvarchar(255) null
	)
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users')
begin
	create table a2security.Users
	(
		Id	bigint not null constraint PK_Users primary key
			constraint DF_Users_PK default(next value for a2security.SQ_Users),
		Tenant int null 
			constraint FK_Users_Tenant_Tenants foreign key references a2security.Tenants(Id),
		UserName nvarchar(255) not null constraint UNQ_Users_UserName unique,
		DomainUser nvarchar(255) null,
		Void bit not null constraint DF_Users_Void default(0),
		SecurityStamp nvarchar(max) not null,
		PasswordHash nvarchar(max) null,
		/*for .net core compatibility*/
		SecurityStamp2 nvarchar(max) null,
		PasswordHash2 nvarchar(max) null,
		ApiUser bit not null constraint DF_Users_ApiUser default(0),
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
		TariffPlan nvarchar(255) null,
		[Guid] uniqueidentifier null,
		Referral bigint null,
		Segment nvarchar(32) null,
		Company bigint null,
			-- constraint FK_Users_Company_Companies foreign key references a2security.Companies(Id)
		DateCreated datetime null
			constraint DF_Users_DateCreated default(a2sys.fn_getCurrentDate()),
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'SecurityStamp2')
begin
	alter table a2security.Users add SecurityStamp2 nvarchar(max) null;
	alter table a2security.Users add PasswordHash2 nvarchar(max) null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'DateCreated')
	alter table a2security.Users add DateCreated datetime null
			constraint DF_Users_DateCreated default(a2sys.fn_getCurrentDate());
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'ApiUser')
	alter table a2security.Users add ApiUser bit not null 
		constraint DF_Users_ApiUser default(0) with values;
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_Users_Locale' and parent_object_id = object_id(N'a2security.Users'))
begin
	alter table a2security.Users drop constraint DF_Users_Locale;
	alter table a2security.Users add constraint DF_Users_Locale2 default('uk-UA') for [Locale] with values;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'Company')
begin
	alter table a2security.Users add Company bigint null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'UserLogins')
begin
	create table a2security.UserLogins
	(
		[User] bigint not null 
			constraint FK_UserLogins_User_Users foreign key references a2security.Users(Id),
		[LoginProvider] nvarchar(255) not null,
		[ProviderKey] nvarchar(max) not null,
		constraint PK_UserLogins primary key([User], LoginProvider) with (fillfactor = 70)
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'Void')
begin
	alter table a2security.Users add Void bit not null constraint DF_Users_Void default(0) with values;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'DomainUser')
begin
	alter table a2security.Users add DomainUser nvarchar(255) null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'ChangePasswordEnabled')
begin
	alter table a2security.Users add ChangePasswordEnabled bit not null constraint DF_Users_ChangePasswordEnabled default(1) with values;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'LastLoginDate')
begin
	alter table a2security.Users add LastLoginDate datetime null;
	alter table a2security.Users add LastLoginHost nvarchar(255) null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'RegisterHost')
begin
	alter table a2security.Users add RegisterHost nvarchar(255) null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'TariffPlan')
begin
	alter table a2security.Users add TariffPlan nvarchar(255) null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'Guid')
begin
	alter table a2security.Users add [Guid] uniqueidentifier null
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'Referral')
begin
	alter table a2security.Users add Referral bigint null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'Segment')
begin
	alter table a2security.Users add Segment nvarchar(32) null;
end
go
------------------------------------------------
if not exists (select * from sys.indexes where object_id = object_id(N'a2security.Users') and name = N'UNQ_Users_DomainUser')
	create unique index UNQ_Users_DomainUser on a2security.Users(DomainUser) where DomainUser is not null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Users' and COLUMN_NAME=N'Tenant')
begin
	alter table a2security.Users add Tenant int null 
			constraint FK_Users_Tenant_Tenants foreign key references a2security.Tenants(Id);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2security' and SEQUENCE_NAME=N'SQ_Groups')
	create sequence a2security.SQ_Groups as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Groups')
begin
	create table a2security.Groups
	(
		Id	bigint not null constraint PK_Groups primary key
			constraint DF_Groups_PK default(next value for a2security.SQ_Groups),
		Void bit not null constraint DF_Groups_Void default(0),				
		[Name] nvarchar(255) not null constraint UNQ_Groups_Name unique,
		[Key] nvarchar(255) null,
		Memo nvarchar(255) null
	)
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Groups' and COLUMN_NAME=N'Void')
begin
	alter table a2security.Groups add Void bit not null constraint DF_Groups_Void default(0) with values;
end
go
------------------------------------------------
if not exists (select * from sys.indexes where object_id = object_id(N'a2security.Groups') and name = N'UNQ_Group_Key')
	create unique index UNQ_Group_Key on a2security.Groups([Key]) where [Key] is not null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'UserGroups')
begin
	-- user groups
	create table a2security.UserGroups
	(
		UserId	bigint	not null
			constraint FK_UserGroups_UsersId_Users foreign key references a2security.Users(Id),
		GroupId bigint	not null
			constraint FK_UserGroups_GroupId_Groups foreign key references a2security.Groups(Id),
		constraint PK_UserGroups primary key clustered (UserId, GroupId) with (fillfactor = 70)
	)
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2security' and SEQUENCE_NAME=N'SQ_Roles')
	create sequence a2security.SQ_Roles as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Roles')
begin
	create table a2security.Roles
	(
		Id	bigint not null constraint PK_Roles primary key
			constraint DF_Roles_PK default(next value for a2security.SQ_Roles),
		Void bit not null constraint DF_Roles_Void default(0),				
		[Name] nvarchar(255) not null constraint UNQ_Roles_Name unique,
		[Key] nvarchar(255) null,
		Memo nvarchar(255) null
	)
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Roles' and COLUMN_NAME=N'Void')
begin
	alter table a2security.Roles add Void bit not null constraint DF_Roles_Void default(0) with values;
end
go
------------------------------------------------
if not exists (select * from sys.indexes where object_id = object_id(N'a2security.Roles') and name = N'UNQ_Role_Key')
	create unique index UNQ_Role_Key on a2security.Roles([Key]) where [Key] is not null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2security' and SEQUENCE_NAME=N'SQ_UserRoles')
	create sequence a2security.SQ_UserRoles as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'UserRoles')
begin
	create table a2security.UserRoles
	(
		Id	bigint	not null constraint PK_UserRoles primary key
			constraint DF_UserRoles_PK default(next value for a2security.SQ_UserRoles),
		RoleId bigint null
			constraint FK_UserRoles_RoleId_Roles foreign key references a2security.Roles(Id),
		UserId	bigint	null
			constraint FK_UserRoles_UserId_Users foreign key references a2security.Users(Id),
		GroupId bigint null 
			constraint FK_UserRoles_GroupId_Groups foreign key references a2security.Groups(Id)
	)
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'ApiUserLogins')
begin
	create table a2security.ApiUserLogins
	(
		[User] bigint not null 
			constraint FK_ApiUserLogins_User_Users foreign key references a2security.Users(Id),
		[Mode] nvarchar(16) not null, -- ApiKey, OAuth2, JWT
		[ClientId] nvarchar(255),
		[ClientSecret] nvarchar(255),
		[ApiKey] nvarchar(255),
		[AllowIP] nvarchar(1024),
		Memo nvarchar(255),
		RedirectUrl nvarchar(255),
		[DateModified] datetime not null constraint DF_ApiUserLogins_DateModified default(a2sys.fn_getCurrentDate()),
		constraint PK_ApiUserLogins primary key clustered ([User], Mode) with (fillfactor = 70)
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'ApiUserLogins' and COLUMN_NAME=N'RedirectUrl')
	alter table a2security.ApiUserLogins add RedirectUrl nvarchar(255);
go
------------------------------------------------
if not exists (select * from sys.indexes where object_id = object_id(N'a2security.ApiUserLogins') and name = N'UNQ_ApiUserLogins_ApiKey')
	create unique index UNQ_ApiUserLogins_ApiKey on a2security.ApiUserLogins(ApiKey) where ApiKey is not null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2security' and SEQUENCE_NAME=N'SQ_Acl')
	create sequence a2security.SQ_Acl as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Acl')
begin
	-- access control list
	create table a2security.[Acl]
	(
		Id	bigint not null constraint PK_Acl primary key
			constraint DF_Acl_PK default(next value for a2security.SQ_Acl),
		[Object] sysname not null,
		[ObjectId] bigint null,
		[ObjectKey] nvarchar(16) null,
		UserId bigint null 
			constraint FK_Acl_UserId_Users foreign key references a2security.Users(Id),
		GroupId bigint null 
			constraint FK_Acl_GroupId_Groups foreign key references a2security.Groups(Id),
		CanView smallint not null	-- 0
			constraint CK_Acl_CanView check(CanView in (0, 1, -1))
			constraint DF_Acl_CanView default(0),
		CanEdit smallint not null	-- 1
			constraint CK_Acl_CanEdit check(CanEdit in (0, 1, -1))
			constraint DF_Acl_CanEdit default(0),
		CanDelete smallint not null	-- 2
			constraint CK_Acl_CanDelete check(CanDelete in (0, 1, -1))
			constraint DF_Acl_CanDelete default(0),
		CanApply smallint not null	-- 3
			constraint CK_Acl_CanApply check(CanApply in (0, 1, -1))
			constraint DF_Acl_CanApply default(0)
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Module.Acl')
begin
	-- ACL for Module
	create table a2security.[Module.Acl]
	(
		Module nvarchar(16) not null 
			constraint FK_ModuleAcl_Modules foreign key references a2security.Modules(Id),
		UserId bigint not null 
			constraint FK_ModuleAcl_UserId_Users foreign key references a2security.Users(Id),
		CanView bit null,
		CanEdit bit null,
		CanDelete bit null,
		CanApply bit null,
		[Permissions] as cast(CanView as int) + cast(CanEdit as int) * 2 + cast(CanDelete as int) * 4 + cast(CanApply as int) * 8
		constraint PK_ModuleAcl primary key clustered (Module, UserId) with (fillfactor = 70)
	);
end
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Acl' and COLUMN_NAME = N'ObjectId' and IS_NULLABLE=N'NO')
	alter table a2security.[Acl] alter column [ObjectId] bigint null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'a2security' and TABLE_NAME = N'Acl' and COLUMN_NAME = N'ObjectKey')
	alter table a2security.[Acl] add [ObjectKey] nvarchar(16) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'LogCodes')
create table a2security.[LogCodes]
(
	Code int not null constraint PK_LogCodes primary key,
	[Name] nvarchar(32) not null
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Log')
begin
	create table a2security.[Log]
	(
		Id	bigint not null identity(100, 1) constraint PK_Log primary key,
		UserId bigint not null
			constraint FK_Log_UserId_Users foreign key references a2security.Users(Id),
		Code int not null
			constraint FK_Log_Code_Codes foreign key references a2security.LogCodes(Code),
		EventTime	datetime not null
			constraint DF_Log_EventTime2 default(a2sys.fn_getCurrentDate()),
		Severity nchar(1) not null,
		Host nvarchar(255) null,
		[Message] nvarchar(max) sparse null
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Log' and COLUMN_NAME=N'Code')
begin
	alter table a2security.[Log] add Code int not null
		constraint FK_Log_Code_Codes foreign key references a2security.LogCodes(Code);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Log' and COLUMN_NAME=N'Host')
	alter table a2security.[Log] add Host nvarchar(255) null;
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_Log_UtcEventTime' and parent_object_id = object_id(N'a2security.Log'))
begin
	alter table a2security.[Log] drop constraint DF_Log_UtcEventTime;
	alter table a2security.[Log] add constraint DF_Log_EventTime2 default(a2sys.fn_getCurrentDate()) for EventTime with values;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2security' and SEQUENCE_NAME=N'SQ_Referrals')
	create sequence a2security.SQ_Referrals as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Referrals')
begin
	create table a2security.Referrals
	(
		Id	bigint not null constraint PK_Referrals primary key
			constraint DF_Referrals_PK default(next value for a2security.SQ_Referrals),
		Void bit not null constraint DF_Referrals_Void default(0),				
		[Type] nchar(1) not null, /* (S)ystem, (C)ustomer */
		[Link] nvarchar(255) not null constraint UNQ_Referrals_Link unique,
		UserCreated bigint not null
			constraint FK_Referrals_UserCreated_Users foreign key references a2security.Users(Id),
		DateCreated	datetime not null
			constraint DF_Referrals_DateCreated2 default(a2sys.fn_getCurrentDate()),
		Memo nvarchar(255) null
	)
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Analytics')
begin
	create table a2security.Analytics
	(
		UserId bigint not null constraint PK_Analytics primary key
			constraint FK_Analytics_UserId_Users foreign key references a2security.Users(Id),
		[Value] nvarchar(max) null,
		DateCreated	datetime not null
			constraint DF_Analytics_DateCreated2 default(a2sys.fn_getCurrentDate()),
	)
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'AnalyticTags')
begin
	create table a2security.AnalyticTags
	(
		UserId bigint not null
			constraint FK_AnalyticTags_UserId_Users foreign key references a2security.Users(Id),
		[Name] nvarchar(255),
		[Value] nvarchar(max) null,
			constraint PK_AnalyticTags primary key clustered (UserId, [Name]) with (fillfactor = 70)
	)
end
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_License_UtcDateCreated' and parent_object_id = object_id(N'a2security.Referrals'))
begin
	alter table a2security.Referrals drop constraint DF_Referrals_DateCreated;
	alter table a2security.Referrals add constraint DF_Referrals_DateCreated2 default(a2sys.fn_getCurrentDate()) for DateCreated with values;
end
go

------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_SCHEMA = N'a2security' and CONSTRAINT_NAME = N'FK_Users_Referral_Referrals')
begin
	alter table a2security.Users add constraint FK_Users_Referral_Referrals foreign key (Referral) references a2security.Referrals(Id);
end
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.VIEWS where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'ViewUsers')
begin
	drop view a2security.ViewUsers;
end
go
------------------------------------------------
create view a2security.ViewUsers
as
	select Id, UserName, DomainUser, PasswordHash, SecurityStamp, Email, PhoneNumber,
		LockoutEnabled, AccessFailedCount, LockoutEndDateUtc, TwoFactorEnabled, [Locale],
		PersonName, Memo, Void, LastLoginDate, LastLoginHost, Tenant, EmailConfirmed,
		PhoneNumberConfirmed, RegisterHost, ChangePasswordEnabled, TariffPlan, Segment,
		IsAdmin = cast(case when ug.GroupId = 77 /*predefined: admins*/ then 1 else 0 end as bit),
		IsTenantAdmin = cast(case when exists(select * from a2security.Tenants where [Admin] = u.Id) then 1 else 0 end as bit),
		SecurityStamp2, PasswordHash2, Company
	from a2security.Users u
		left join a2security.UserGroups ug on u.Id = ug.UserId and ug.GroupId=77 /*predefined: admins*/
	where Void=0 and Id <> 0 and ApiUser = 0;
go
------------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2security.fn_isUserTenantAdmin') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2security.fn_isUserTenantAdmin;
go
------------------------------------------------
create function a2security.fn_isUserTenantAdmin(@TenantId int, @UserId bigint)
returns bit
as
begin
	return case when 
		exists(select * from a2security.Tenants where Id = @TenantId and [Admin] = @UserId) then 1 
	else 0 end;
end
go
------------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2security.fn_isUserAdmin') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2security.fn_isUserAdmin;
go
------------------------------------------------
create function a2security.fn_isUserAdmin(@UserId bigint)
returns bit
as
begin
	return case when 
		exists(select * from a2security.UserGroups where GroupId=77 /*predefined: admins */ and UserId = @UserId) then 1 
	else 0 end;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'WriteLog')
	drop procedure a2security.[WriteLog]
go
------------------------------------------------
create procedure [a2security].[WriteLog]
	@UserId bigint = null,
	@SeverityChar nchar(1),
	@Code int = null,
	@Message nvarchar(max) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	insert into a2security.[Log] (UserId, Severity, [Code] , [Message]) 
		values (isnull(@UserId, 0 /*system user*/), @SeverityChar, @Code, @Message);
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'FindUserById')
	drop procedure a2security.FindUserById
go
------------------------------------------------
create procedure a2security.FindUserById
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select * from a2security.ViewUsers where Id=@Id;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'FindUserByName')
	drop procedure a2security.FindUserByName
go
------------------------------------------------
create procedure a2security.FindUserByName
@UserName nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select * from a2security.ViewUsers where UserName=@UserName;
end
go

------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'FindUserByEmail')
	drop procedure a2security.FindUserByEmail
go
------------------------------------------------
create procedure a2security.FindUserByEmail
@Email nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select * from a2security.ViewUsers where Email=@Email;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'FindUserByPhoneNumber')
	drop procedure a2security.FindUserByPhoneNumber
go
------------------------------------------------
create procedure a2security.FindUserByPhoneNumber
@PhoneNumber nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select * from a2security.ViewUsers where PhoneNumber=@PhoneNumber;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'FindUserByLogin')
	drop procedure a2security.FindUserByLogin
go
------------------------------------------------
create procedure a2security.[FindUserByLogin]
@LoginProvider nvarchar(255),
@ProviderKey nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @UserId bigint;

	select @UserId = [User] from a2security.UserLogins where LoginProvider = @LoginProvider and ProviderKey = @ProviderKey;

	select * from a2security.ViewUsers where Id=@UserId;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'AddUserLogin')
	drop procedure a2security.[AddUserLogin]
go
------------------------------------------------
create procedure a2security.AddUserLogin
@UserId bigint,
@LoginProvider nvarchar(255),
@ProviderKey nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	if not exists(select * from a2security.UserLogins where [User]=@UserId and LoginProvider=@LoginProvider)
	begin
		insert into a2security.UserLogins([User], [LoginProvider], [ProviderKey]) 
			values (@UserId, @LoginProvider, @ProviderKey);
	end
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'FindApiUserByApiKey')
	drop procedure a2security.FindApiUserByApiKey
go
------------------------------------------------
create procedure a2security.FindApiUserByApiKey
@Host nvarchar(255) = null,
@ApiKey nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @status nvarchar(255);
	declare @code int;

	set @status = N'ApiKey=' + @ApiKey;
	set @code = 65; /*fail*/

	declare @user table(Id bigint, Tenant int, Segment nvarchar(255), [Name] nvarchar(255), ClientId nvarchar(255), AllowIP nvarchar(255));
	insert into @user(Id, Tenant, Segment, [Name], ClientId, AllowIP)
	select top(1) u.Id, u.Tenant, Segment, [Name]=u.UserName, s.ClientId, s.AllowIP 
	from a2security.Users u inner join a2security.ApiUserLogins s on u.Id = s.[User]
	where u.Void=0 and s.Mode = N'ApiKey' and s.ApiKey=@ApiKey;
	
	if @@rowcount > 0 
	begin
		set @code = 64 /*sucess*/;
		update a2security.Users set LastLoginDate=getutcdate(), LastLoginHost=@Host
		from @user t inner join a2security.Users u on t.Id = u.Id;
	end

	insert into a2security.[Log] (UserId, Severity, Code, Host, [Message])
		values (0, N'I', @code, @Host, @status);

	select * from @user;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'FindApiUserByBasic')
	drop procedure a2security.FindApiUserByBasic
go
------------------------------------------------
create procedure a2security.FindApiUserByBasic
@Host nvarchar(255) = null,
@ClientId nvarchar(255) = null,
@ClientSecret nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @status nvarchar(255);
	declare @code int;

	set @status = N'Basic=' + @ClientId;
	set @code = 65; /*fail*/

	declare @usertable table(Id bigint, Tenant int, Segment nvarchar(255), [Name] nvarchar(255), ClientId nvarchar(255), AllowIP nvarchar(255));

	insert into @usertable(Id, Tenant, Segment, [Name], ClientId, AllowIP)
	select top(1) u.Id, u.Tenant, Segment, [Name]=u.UserName, s.ClientId, s.AllowIP 
	from a2security.Users u inner join a2security.ApiUserLogins s on u.Id = s.[User]
	where u.Void=0 and s.Mode = N'Basic' and s.ClientId = @ClientId and s.ClientSecret = @ClientSecret;
	
	if @@rowcount > 0 
	begin
		set @code = 64 /*sucess*/;
		update a2security.Users set LastLoginDate=getutcdate(), LastLoginHost=@Host
			from @usertable t inner join a2security.Users u on t.Id = u.Id;
	end

	insert into a2security.[Log] (UserId, Severity, Code, Host, [Message])
		values (0, N'I', @code, @Host, @status);

	select * from @usertable;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'UpdateUserPassword')
	drop procedure a2security.UpdateUserPassword
go
------------------------------------------------
create procedure a2security.UpdateUserPassword
@Id bigint,
@PasswordHash nvarchar(max),
@SecurityStamp nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update a2security.ViewUsers set PasswordHash = @PasswordHash, SecurityStamp = @SecurityStamp where Id=@Id;
	exec a2security.[WriteLog] @Id, N'I', 15; /*PasswordUpdated*/
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'UpdateUserLockout')
	drop procedure a2security.UpdateUserLockout
go
------------------------------------------------
create procedure a2security.UpdateUserLockout
@Id bigint,
@AccessFailedCount int,
@LockoutEndDateUtc datetimeoffset
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	update a2security.ViewUsers set 
		AccessFailedCount = @AccessFailedCount, LockoutEndDateUtc = @LockoutEndDateUtc
	where Id=@Id;
	declare @msg nvarchar(255);
	set @msg = N'AccessFailedCount: ' + cast(@AccessFailedCount as nvarchar(255));
	exec a2security.[WriteLog] @Id, N'E', 18, /*AccessFailedCount*/ @msg;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'UpdateUserLogin')
	drop procedure a2security.UpdateUserLogin
go
------------------------------------------------
create procedure a2security.UpdateUserLogin
@Id bigint,
@LastLoginDate datetime,
@LastLoginHost nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	update a2security.ViewUsers set LastLoginDate = @LastLoginDate, LastLoginHost = @LastLoginHost where Id=@Id;
	exec a2security.[WriteLog] @Id, N'I', 1; /*Login*/
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'ConfirmEmail')
	drop procedure a2security.ConfirmEmail
go
------------------------------------------------
create procedure a2security.ConfirmEmail
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update a2security.ViewUsers set EmailConfirmed = 1 where Id=@Id;

	declare @msg nvarchar(255);
	select @msg = N'Email: ' + Email from a2security.ViewUsers where Id=@Id;
	exec a2security.[WriteLog] @Id, N'I', 26, /*EmailConfirmed*/ @msg;
end
go

------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'ConfirmPhoneNumber')
	drop procedure a2security.ConfirmPhoneNumber
go
------------------------------------------------
create procedure a2security.ConfirmPhoneNumber
@Id bigint,
@PhoneNumber nvarchar(255),
@PhoneNumberConfirmed bit,
@SecurityStamp nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	update a2security.ViewUsers set PhoneNumber = @PhoneNumber,
		PhoneNumberConfirmed = @PhoneNumberConfirmed, SecurityStamp=@SecurityStamp
	where Id=@Id;

	declare @msg nvarchar(255);
	set @msg = N'PhoneNumber: ' + @PhoneNumber;
	exec a2security.[WriteLog] @Id, N'I', 27, /*PhoneNumberConfirmed*/ @msg;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'GetUserGroups')
	drop procedure a2security.GetUserGroups
go
------------------------------------------------
create procedure a2security.GetUserGroups
@UserId bigint
as
begin
	set nocount on;
	select g.Id, g.[Name], g.[Key]
	from a2security.UserGroups ug
		inner join a2security.Groups g on ug.GroupId = g.Id
	where ug.UserId = @UserId and g.Void=0;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.UpdateUserInfo')
	drop procedure [a2security].[Permission.UpdateUserInfo]
go
------------------------------------------------
create procedure [a2security].[Permission.UpdateUserInfo]
as
begin
	set nocount on;
	declare @procName sysname;
	declare @sqlProc sysname;
	declare #tmpcrs cursor local fast_forward read_only for
		select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES 
			where ROUTINE_SCHEMA = N'a2security' and ROUTINE_NAME like N'Permission.UpdateAcl.%';
	open #tmpcrs;
	fetch next from #tmpcrs into @procName;
	while @@fetch_status = 0
	begin
		set @sqlProc = N'a2security.[' + @procName + N']';
		exec sp_executesql @sqlProc;
		fetch next from #tmpcrs into @procName;
	end
	close #tmpcrs;
	deallocate #tmpcrs;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'CreateUser')
	drop procedure a2security.CreateUser
go
------------------------------------------------
create procedure a2security.CreateUser
@UserName nvarchar(255),
@PasswordHash nvarchar(max) = null,
@SecurityStamp nvarchar(max),
@Email nvarchar(255) = null,
@PhoneNumber nvarchar(255) = null,
@Tenant int = null,
@PersonName nvarchar(255) = null,
@RegisterHost nvarchar(255) = null,
@Memo nvarchar(255) = null,
@TariffPlan nvarchar(255) = null,
@Locale nvarchar(255) = null,
@RetId bigint output
as
begin
	-- from account/register only
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	set @Locale = isnull(@Locale, N'uk-UA')

	declare @userId bigint; 

	if @Tenant = -1
	begin
		declare @tenants table(id int);
		declare @users table(id bigint);
		declare @tenantId int;

		begin tran;
		insert into a2security.Tenants([Admin], Locale)
			output inserted.Id into @tenants(id)
		values (null, @Locale);

		select top(1) @tenantId = id from @tenants;

		insert into a2security.ViewUsers(UserName, PasswordHash, SecurityStamp, Email, PhoneNumber, Tenant, PersonName, 
			RegisterHost, Memo, TariffPlan, Segment, Locale)
			output inserted.Id into @users(id)
			values (@UserName, @PasswordHash, @SecurityStamp, @Email, @PhoneNumber, @tenantId, @PersonName, 
				@RegisterHost, @Memo, @TariffPlan, a2security.fn_GetCurrentSegment(), @Locale);
		select top(1) @userId = id from @users;

		update a2security.Tenants set [Admin] = @userId where Id=@tenantId;

		insert into a2security.UserGroups(UserId, GroupId) values (@userId, 1 /*all users*/);

		if exists(select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = N'a2security' and ROUTINE_NAME=N'OnCreateNewUser')
		begin
			declare @sql nvarchar(255);
			declare @prms nvarchar(255);
			set @sql = N'a2security.OnCreateNewUser @TenantId, @CompanyId, @UserId';
			set @prms = N'@TenantId int, @CompanyId bigint, @UserId bigint';
			exec sp_executesql @sql, @prms, @tenantId, 1, @userId;
		end
		commit tran;
	end
	else
	begin
		begin tran;

		insert into a2security.ViewUsers(UserName, PasswordHash, SecurityStamp, Email, PhoneNumber, PersonName, RegisterHost, Memo, TariffPlan, Locale)
			output inserted.Id into @users(id)
			values (@UserName, @PasswordHash, @SecurityStamp, @Email, @PhoneNumber, @PersonName, @RegisterHost, @Memo, @TariffPlan, @Locale);
		select top(1) @userId = id from @users;

		insert into a2security.UserGroups(UserId, GroupId) values (@userId, 1 /*all users*/);
		commit tran;

		exec a2security.[Permission.UpdateUserInfo];

	end
	set @RetId = @userId;

	declare @msg nvarchar(255);
	set @msg = N'User: ' + @UserName;
	exec a2security.[WriteLog] @RetId, N'I', 2, /*UserCreated*/ @msg;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'CreateUserSimple')
	drop procedure a2security.CreateUserSimple
go
------------------------------------------------
create procedure a2security.CreateUserSimple
@Tenant int = null,
@UserName nvarchar(255),
@Email nvarchar(255) = null,
@PhoneNumber nvarchar(255) = null,
@PersonName nvarchar(255) = null,
@Memo nvarchar(255) = null,
@Locale nvarchar(255) = null,
@RetId bigint output
as
begin
	-- from CreateTenantUserHandler only
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @rtable table(id bigint);
	declare @userId bigint;
	declare @segment bigint;
	select @segment = u.Segment, @Locale=isnull(@Locale, u.Locale) from 
		a2security.Users u inner join a2security.Tenants  t on t.[Admin] = u.Id
	where t.Id = @Tenant;

	begin tran;
	insert into a2security.Users(Tenant, UserName, Email, PersonName, PhoneNumber, Memo, Locale, EmailConfirmed, SecurityStamp, 
		PasswordHash, Segment)
	output inserted.Id into @rtable(id)
	values (@Tenant, @UserName, @Email, @PersonName, @PhoneNumber, @Memo, isnull(@Locale, N''), 1, N'', N'', @segment);
	select @userId = id from @rtable;
	insert into a2security.UserGroups(UserId, GroupId) values (@userId, 1 /*all users*/);
	commit tran;

	declare @msg nvarchar(255);
	set @msg = N'User: ' + @UserName;
	exec a2security.[WriteLog] @RetId, N'I', 2, /*UserCreated*/ @msg;

	set @RetId = @userId;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.Check')
	drop procedure a2security.[Permission.Check]
go
------------------------------------------------
create procedure a2security.[Permission.Check]
	@UserId bigint,
	@CompanyId bigint = 0,
	@Module nvarchar(255),
	@CanEdit bit = null output,
	@CanDelete bit = null output,
	@CanApply bit = null output,
	@Permissions int = null output
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @_canView bit = 0;
	declare @_canEdit bit = 0;
	declare @_canDelete bit = 0;
	declare @_canApply bit = 0;
	declare @_permissions int = 0;


	if @UserId = 0 or 1 = a2security.fn_isUserAdmin(@UserId)
	begin
		set @CanEdit = 1;
		set @CanDelete = 1;
		set @CanApply = 1;
		set @Permissions = 15;
	end
	else
	begin
		select @_canView = CanView, @_canEdit = CanEdit, @_canDelete = CanDelete, @_canApply = CanApply,
			@_permissions = [Permissions]
		from a2security.[Module.Acl]
		where [Module] = @Module and [UserId] = @UserId

		if isnull(@_canView, 0) = 0
			throw 60000, N'@[UIError.AccessDenied]', 0;
		else
		begin
			set @CanEdit = @_canEdit;
			set @CanDelete = @_canDelete;
			set @CanApply = @_canApply;
			set @Permissions = @_permissions;
		end
	end
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.Check.Apply')
	drop procedure a2security.[Permission.Check.Apply]
go
------------------------------------------------
create procedure a2security.[Permission.Check.Apply]
	@UserId bigint,
	@CompanyId bigint = 0,
	@Module nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @_canApply bit;
	exec a2security.[Permission.Check] 
		@UserId = @UserId, @CompanyId = @CompanyId, @Module = @Module, @CanApply = @_canApply output;
	if @_canApply = 0
		throw 60000, N'@[UIError.AccessDenied]', 0;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.Check.Edit')
	drop procedure a2security.[Permission.Check.Edit]
go
------------------------------------------------
create procedure a2security.[Permission.Check.Edit]
	@UserId bigint,
	@CompanyId bigint = 0,
	@Module nvarchar(255),
	@Permissions int = null output
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @_canEdit bit;
	exec a2security.[Permission.Check] 
		@UserId = @UserId, @CompanyId = @CompanyId, @Module = @Module, 
		@CanEdit = @_canEdit output, @Permissions = @Permissions output;
	if @_canEdit = 0
		throw 60000, N'@[UIError.AccessDenied]', 0;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.Check.Delete')
	drop procedure a2security.[Permission.Check.Delete]
go
------------------------------------------------
create procedure a2security.[Permission.Check.Delete]
	@UserId bigint,
	@CompanyId bigint = 0,
	@Module nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @_canDelete bit;
	exec a2security.[Permission.Check] 
		@UserId = @UserId, @CompanyId = @CompanyId, @Module = @Module, @CanDelete = @_canDelete output;
	if @_canDelete = 0
		throw 60000, N'@[UIError.AccessDenied]', 0;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.Get')
	drop procedure a2security.[Permission.Get]
go
------------------------------------------------
create procedure a2security.[Permission.Get]
	@UserId bigint,
	@CompanyId bigint = 0,
	@Module nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @_permissions int = 0;
	exec a2security.[Permission.Check] 
		@UserId = @UserId, @CompanyId = @CompanyId, @Module = @Module, @Permissions = @_permissions output;
	return @_permissions;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.ChangePassword.Load')
	drop procedure a2security.[User.ChangePassword.Load]
go
------------------------------------------------
create procedure a2security.[User.ChangePassword.Load]
	@TenantId int = 0,
	@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	if 1 <> (select ChangePasswordEnabled from a2security.Users where Id=@UserId)
	begin
		raiserror (N'UI:@[ChangePasswordDisabled]', 16, -1) with nowait;
	end
	select [User!TUser!Object] = null, [Id!!Id] = Id, [Name!!Name] = UserName, 
		[OldPassword] = cast(null as nvarchar(255)),
		[NewPassword] = cast(null as nvarchar(255)),
		[ConfirmPassword] = cast(null as nvarchar(255)) 
	from a2security.Users where Id=@UserId;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Login.CheckDuplicate')
	drop procedure a2security.[Login.CheckDuplicate]
go
------------------------------------------------
create procedure a2security.[Login.CheckDuplicate]
	@TenantId int = null,
	@UserId bigint,
	@Id bigint,
	@CompanyId bigint = 1,
	@Login nvarchar(255) = null
as
begin
	set nocount on;
	declare @valid bit = 1;
	if exists(select * from a2security.Users where UserName = @Login and Id <> @Id)
		set @valid = 0;
	select [Result!TResult!Object] = null, [Value] = @valid;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'PhoneNumber.CheckDuplicate')
	drop procedure a2security.[PhoneNumber.CheckDuplicate]
go
------------------------------------------------
create procedure a2security.[PhoneNumber.CheckDuplicate]
	@TenantId int = null,
	@UserId bigint,
	@Id bigint,
	@CompanyId bigint = 1,
	@PhoneNumber nvarchar(255) = null
as
begin
	set nocount on;
	declare @valid bit = 1;
	if exists(select * from a2security.Users where PhoneNumber = @PhoneNumber and Id <> @Id)
		set @valid = 0;
	select [Result!TResult!Object] = null, [Value] = @valid;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'UserStateInfo.Load')
	drop procedure a2security.[UserStateInfo.Load]
go
------------------------------------------------
create procedure a2security.[UserStateInfo.Load]
@TenantId int = null,
@UserId bigint
as
begin
	select [UserState!TUserState!Object] = null;
end
go
------------------------------------------------
begin
	set nocount on;
	declare @codes table (Code int, [Name] nvarchar(32))

	insert into @codes(Code, [Name])
	values
		(1,  N'Login'		        ), 
		(2,  N'UserCreated'         ), 
		(3,  N'TeantUserCreated'    ), 
		(15, N'PasswordUpdated'     ), 
		(18, N'AccessFailedCount'   ), 
		(26, N'EmailConfirmed'      ), 
		(27, N'PhoneNumberConfirmed'),
		(64, N'ApiKey: Success'     ), 
		(65, N'ApiKey: Fail'        ),
		(66, N'ApiKey: IP forbidden'); 

	merge into a2security.[LogCodes] t
	using @codes s on s.Code = t.Code
	when matched then update set
		[Name]=s.[Name]
	when not matched by target then insert 
		(Code, [Name]) values (s.Code, s.[Name])
	when not matched by source then delete;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'SaveReferral')
	drop procedure a2security.SaveReferral
go
------------------------------------------------
create procedure a2security.SaveReferral
@UserId bigint,
@Referral nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	declare @refid bigint;
	select @refid = Id from a2security.Referrals where lower(Link) = lower(@Referral);
	if @refid is not null
		update a2security.Users set Referral = @refid where Id=@UserId;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'DeleteUser')
	drop procedure a2security.DeleteUser
go
------------------------------------------------
create procedure a2security.DeleteUser
@CurrentUser bigint,
@Tenant bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	declare @TenantAdmin bigint;
	select @TenantAdmin = [Admin] from a2security.Tenants where Id = @Tenant;
	if @TenantAdmin <> @CurrentUser
	begin
		raiserror(N'Invalid teanant administrator', 16, 1);
		return;
	end
	if @TenantAdmin = @Id
	begin
		raiserror(N'Unable to delete tenant administrator', 16, 1);
		return;
	end
	begin try
		begin tran
		delete from a2security.UserRoles where UserId = @Id;
		delete from a2security.UserGroups where UserId = @Id;
		delete from a2security.[Menu.Acl] where UserId = @Id;
		delete from a2security.[Log] where UserId = @Id;
		delete from a2security.Users where Tenant = @Tenant and Id = @Id;
		commit tran
	end try
	begin catch
		if @@trancount > 0
		begin
			rollback tran;
		end
		declare @msg nvarchar(255);
		set @msg = error_message();
		raiserror(@msg, 16, 1);
	end catch
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.CheckRegister')
	drop procedure a2security.[User.CheckRegister]
go
------------------------------------------------
create procedure a2security.[User.CheckRegister]
@UserName nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @Id bigint;

	select @Id = Id from a2security.Users where UserName=@UserName and EmailConfirmed = 0 and PhoneNumberConfirmed = 0;

	if @Id is not null
	begin
		declare @uid nvarchar(255);
		set @uid = N'_' + convert(nvarchar(255), newid());
		update a2security.Users set Void=1, UserName = UserName + @uid, 
			Email = Email + @uid, PhoneNumber = PhoneNumber + @uid, PasswordHash = null, SecurityStamp = N''
		where Id=@Id and EmailConfirmed = 0  and PhoneNumberConfirmed = 0 and UserName=@UserName;
	end
end
go
------------------------------------------------
set nocount on;
begin
	-- predefined users and groups
	if not exists(select * from a2security.Users where Id = 0)
		insert into a2security.Users (Id, UserName, SecurityStamp) values (0, N'System', N'System');
	if not exists(select * from a2security.Groups where Id = 1)
		insert into a2security.Groups(Id, [Key], [Name]) values (1, N'Users', N'@[AllUsers]');
	if not exists(select * from a2security.Groups where Id = 77)
		insert into a2security.Groups(Id, [Key], [Name]) values (77, N'Admins', N'@[AdminUsers]');
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'License')
begin
	create table a2security.License
	(
		[Text] nvarchar(max) not null,
		DateCreated datetime not null constraint DF_License_DateCreated2 default(a2sys.fn_getCurrentDate()),
		DateModified datetime not null constraint DF_License_DateModified2 default (a2sys.fn_getCurrentDate())
	);
end
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_License_UtcDateCreated' and parent_object_id = object_id(N'a2security.License'))
begin
	alter table a2security.License drop constraint DF_License_UtcDateCreated;
	alter table a2security.License add constraint DF_License_DateCreated2 default(a2sys.fn_getCurrentDate()) for DateCreated with values;
end
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_License_UtcDateModified' and parent_object_id = object_id(N'a2security.License'))
begin
	alter table a2security.License drop constraint DF_License_UtcDateModified;
	alter table a2security.License add constraint DF_License_DateModified2 default(a2sys.fn_getCurrentDate()) for DateModified with values;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'License.Load')
	drop procedure a2security.[License.Load]
go
------------------------------------------------
create procedure a2security.[License.Load]
as
begin
	set nocount on;
	select [Text] from a2security.License;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'License.Update')
	drop procedure a2security.[License.Update]
go
------------------------------------------------
create procedure a2security.[License.Update]
@License nvarchar(max)
as
begin
	set nocount on;
	if exists(select * from a2security.License)
		update a2security.License set [Text]=@License, DateModified = a2sys.fn_getCurrentDate();
	else
		insert into a2security.License ([Text]) values (@License);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2security' and SEQUENCE_NAME=N'SQ_Companies')
	create sequence a2security.SQ_Companies as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Companies')
begin
	create table a2security.Companies
	(
		Id	bigint not null constraint PK_Companies primary key
			constraint DF_Companies_PK default(next value for a2security.SQ_Companies),
		[Name] nvarchar(255) null,
		Memo nvarchar(255) null
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'UserCompanies')
begin
	create table a2security.[UserCompanies]
	(
		[User] bigint not null
			constraint FK_UserCompanies_User_Users foreign key references a2security.Users(Id),
		[Company] bigint not null
			constraint FK_UserCompanies_Company_Companies foreign key references a2security.Companies(Id),
		[Enabled] bit,
		constraint PK_UserCompanies primary key clustered ([User], [Company]) with (fillfactor = 70)
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_SCHEMA = N'a2security' and CONSTRAINT_NAME = N'FK_Users_Company_Companies')
	alter table a2security.Users add
		constraint FK_Users_Company_Companies foreign key (Company) references a2security.Companies(Id);
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.Companies.Check')
	drop procedure a2security.[User.Companies.Check]
go
------------------------------------------------
create procedure a2security.[User.Companies.Check]
@UserId bigint,
@Error bit,
@CompanyId bigint output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	declare @isadmin bit;
	declare @id bigint;

	select @id = Id, @isadmin = IsAdmin, @CompanyId = Company from a2security.ViewUsers where Id=@UserId;
	if @id is null
	begin
		raiserror (N'UI:No such user', 16, -1) with nowait;
		return;
	end
	if @isadmin = 1
	begin
		if @CompanyId is null or @CompanyId = 0 or not exists(select * from a2security.Companies where Id=@CompanyId)
		begin
			select top(1) @CompanyId = Id from a2security.Companies where Id <> 0;
			update a2security.ViewUsers set Company = @CompanyId where Id = @UserId;
		end
	end
	else
	begin
		-- not admin
		if @CompanyId is null or @CompanyId = 0 or not exists(select * from a2security.UserCompanies where [User] = @UserId and Company = @CompanyId)
		begin
			select top(1) @CompanyId = Company from a2security.UserCompanies where Company <> 0 and [Enabled]=1 and [User] = @UserId;
			update a2security.ViewUsers set Company = @CompanyId where Id = @UserId;
		end
	end
	if @Error = 1 and @CompanyId is null
	begin
		raiserror (N'UI:No current company', 16, -1) with nowait;
		return;
	end
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.Companies')
	drop procedure a2security.[User.Companies]
go
------------------------------------------------
create procedure a2security.[User.Companies]
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @isadmin bit;
	declare @company bigint;

	select @isadmin = IsAdmin, @company = Company from a2security.ViewUsers where Id=@UserId;

	-- all companies for the current user
	select [Companies!TCompany!Array] = null, 
		Id, [Name], 
		[Current] = cast(case when Id = @company then 1 else 0 end as bit)
	from a2security.Companies c
		left join a2security.UserCompanies uc on uc.Company = c.Id and uc.[User] = @UserId
	where c.Id <> 0 and (@isadmin = 1 or 
		c.Id in (select uc.Company from a2security.UserCompanies uc where uc.[User] = @UserId and uc.[Enabled] = 1))
	order by c.Id;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.SwitchToCompany')
	drop procedure a2security.[User.SwitchToCompany]
go
------------------------------------------------
create procedure a2security.[User.SwitchToCompany]
@UserId bigint,
@CompanyId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	declare @isadmin bit;
	set @isadmin = a2security.fn_isUserAdmin(@UserId);
	if not exists(select * from a2security.Companies where Id=@CompanyId)
		throw 60000, N'There is no such company', 0;
	if @isadmin = 0 and not exists(
			select * from a2security.UserCompanies where [User] = @UserId and Company=@CompanyId and [Enabled] = 1)
		throw 60000, N'There is no such company or it is not allowed', 0;
	update a2security.Users set Company = @CompanyId where Id = @UserId;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.Company.Load')
	drop procedure a2security.[User.Company.Load]
go
------------------------------------------------
create procedure a2security.[User.Company.Load]
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @company bigint;
	select @company = Company from a2security.ViewUsers where Id=@UserId;

	select [UserCompany!TCompany!Object] = null, Company=@company;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.UpdateAcl.Module')
	drop procedure [a2security].[Permission.UpdateAcl.Module]
go
------------------------------------------------
create procedure [a2security].[Permission.UpdateAcl.Module]
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @ModuleTable table (Id varchar(16), UserId bigint, GroupId bigint, 
		CanView smallint, CanEdit smallint, CanDelete smallint, CanApply smallint);

	insert into @ModuleTable (Id, UserId, GroupId, CanView, CanEdit, CanDelete, CanApply)
	select m.Id, a.UserId, a.GroupId, a.CanView, a.CanEdit, a.CanDelete, CanApply
	from a2security.Acl a inner join a2security.Modules m on a.ObjectKey = m.Id
	where a.[Object] = N'std:module';

	declare @UserTable table (ObjectKey varchar(16), UserId bigint, CanView bit, CanEdit bit, CanDelete bit, CanApply bit);

	with T(ObjectKey, UserId, CanView, CanEdit, CanDelete, CanApply)
	as
	(
		select a.Id, UserId=isnull(ur.UserId, a.UserId), a.CanView, a.CanEdit, a.CanDelete, a.CanApply
		from @ModuleTable a
		left join a2security.UserGroups ur on a.GroupId = ur.GroupId
		where isnull(ur.UserId, a.UserId) is not null
	)
	insert into @UserTable(ObjectKey, UserId, CanView, CanEdit, CanDelete, CanApply)
	select ObjectKey, UserId,
		_CanView = isnull(case 
				when min(T.CanView) = -1 then 0
				when max(T.CanView) = 1 then 1
				end, 0),
		_CanEdit = isnull(case
				when min(T.CanEdit) = -1 then 0
				when max(T.CanEdit) = 1 then 1
				end, 0),
		_CanDelete = isnull(case
				when min(T.CanDelete) = -1 then 0
				when max(T.CanDelete) = 1 then 1
				end, 0),
		_CanApply = isnull(case
				when min(T.CanApply) = -1 then 0
				when max(T.CanApply) = 1 then 1
				end, 0)
	from T
	group by ObjectKey, UserId;

	merge a2security.[Module.Acl] as t
	using
	(
		select ObjectKey, UserId, CanView, CanEdit, CanDelete, CanApply
		from @UserTable T
		where CanView = 1
	) as s(ObjectKey, UserId, CanView, CanEdit, CanDelete, CanApply)
		on t.Module = s.[ObjectKey] and t.UserId=s.UserId
	when matched then
		update set 
			t.CanView = s.CanView,
			t.CanEdit = s.CanEdit,
			t.CanDelete = s.CanDelete,
			t.CanApply = s.CanApply
	when not matched by target then
		insert (Module, UserId, CanView, CanEdit, CanDelete, CanApply)
			values (s.[ObjectKey], s.UserId, s.CanView, s.CanEdit, s.CanDelete, s.CanApply)
	when not matched by source then
		delete;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'SaveAnalytics')
	drop procedure a2security.SaveAnalytics
go
------------------------------------------------
create procedure a2security.SaveAnalytics
@UserId bigint,
@Value nvarchar(max),
@Tags a2sys.[NameValue.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	begin tran;
	insert into a2security.Analytics(UserId, [Value]) values (@UserId, @Value);

	with T([Name], [Value]) as (
		select [Name], [Value] = max([Value]) 
		from @Tags 
		where [Name] is not null and [Value] is not null 
		group by [Name]
	)
	insert into a2security.AnalyticTags (UserId, [Name], [Value])
	select @UserId, [Name], [Value] from T;
	commit tran;
end
go
-- .JWT SUPPORT
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'RefreshTokens')
	create table a2security.RefreshTokens
	(
		UserId bigint not null
			constraint FK_RefreshTokens_UserId_Users foreign key references a2security.Users(Id),
		[Provider] nvarchar(64) not null,
		[Token] nvarchar(255) not null,
		Expires datetime not null,
		constraint PK_RefreshTokens primary key (UserId, [Provider], Token) with (fillfactor = 70)
	)
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'AddToken')
	drop procedure a2security.[AddToken]
go
------------------------------------------------
create procedure a2security.[AddToken]
@UserId bigint,
@Provider nvarchar(64),
@Token nvarchar(255),
@Expires datetime,
@Remove nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	begin tran;
	insert into a2security.RefreshTokens(UserId, [Provider], Token, Expires)
		values (@UserId, @Provider, @Token, @Expires);
	if @Remove is not null
		delete from a2security.RefreshTokens 
		where UserId=@UserId and [Provider] = @Provider and Token = @Remove;
	commit tran;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'GetToken')
	drop procedure a2security.[GetToken]
go
------------------------------------------------
create procedure a2security.[GetToken]
@UserId bigint,
@Provider nvarchar(64),
@Token nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	select [Token], UserId, Expires from a2security.RefreshTokens
	where UserId=@UserId and [Provider] = @Provider and Token = @Token;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'RemoveToken')
	drop procedure a2security.[RemoveToken]
go
------------------------------------------------
create procedure a2security.[RemoveToken]
@UserId bigint,
@Provider nvarchar(64),
@Token nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	delete from a2security.RefreshTokens 
	where UserId=@UserId and [Provider] = @Provider and Token = @Token;
end
go
-- .NET CORE SUPPORT
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.SetPasswordHash')
	drop procedure a2security.[User.SetPasswordHash]
go
------------------------------------------------
create procedure a2security.[User.SetPasswordHash]
@UserId bigint,
@PasswordHash nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update a2security.ViewUsers set PasswordHash2 = @PasswordHash where Id=@UserId;
end
go

------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.SetSecurityStamp')
	drop procedure a2security.[User.SetSecurityStamp]
go
------------------------------------------------
create procedure a2security.[User.SetSecurityStamp]
@UserId bigint,
@SecurityStamp nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update a2security.ViewUsers set SecurityStamp2 = @SecurityStamp where Id=@UserId;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'User.SetPhoneNumberConfirmed')
	drop procedure a2security.[User.SetPhoneNumberConfirmed]
go
------------------------------------------------
create procedure a2security.[User.SetPhoneNumberConfirmed]
@UserId bigint,
@Confirmed bit
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update a2security.ViewUsers set PhoneNumberConfirmed = @Confirmed where Id=@UserId;
end
go
------------------------------------------------
begin
	set nocount on;
	grant execute on schema ::a2security to public;
end
go


/*
Copyright © 2008-2021 Alex Kukhtin

Last updated : 09 apr 2020
module version : 7055
*/
------------------------------------------------
exec a2sys.SetVersion N'std:messaging', 7055;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'a2messaging')
begin
	exec sp_executesql N'create schema a2messaging';
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2messaging' and SEQUENCE_NAME=N'SQ_Messages')
	create sequence a2messaging.SQ_Messages as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2messaging' and TABLE_NAME=N'Messages')
begin
	create table a2messaging.[Messages]
	(
		Id	bigint	not null constraint PK_Messages primary key
			constraint DF_Messages_PK default(next value for a2messaging.SQ_Messages),
		Template nvarchar(255) not null,
		[Key] nvarchar(255) not null,
		TargetId bigint null,
		[Source] nvarchar(255) null,
		DateCreated datetime not null constraint DF_Messages_DateCreated2 default(a2sys.fn_getCurrentDate())
	);
end
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_Processes_UtcDateCreated' and parent_object_id = object_id(N'a2messaging.Messages'))
begin
	alter table a2messaging.[Messages] drop constraint DF_Processes_UtcDateCreated;
	alter table a2messaging.[Messages] add constraint DF_Messages_DateCreated2 default(a2sys.fn_getCurrentDate()) for DateCreated with values;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2messaging' and SEQUENCE_NAME=N'SQ_Parameters')
	create sequence a2messaging.SQ_Parameters as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2messaging' and TABLE_NAME=N'Parameters')
begin
	create table a2messaging.[Parameters]
	(
		Id	bigint	not null constraint PK_Parameters primary key
			constraint Parameters_PK default(next value for a2messaging.SQ_Parameters),
		[Message] bigint not null
			constraint FK_Parameters_Messages_Id references a2messaging.[Messages](Id),
		[Name] nvarchar(255) not null,
		[Value] nvarchar(max) null
	);
end
go
------------------------------------------------
if not exists (select * from sys.indexes where object_id = object_id(N'a2messaging.Parameters') and name = N'IX_MessagingParameters_Message')
	create nonclustered index IX_MessagingParameters_Message on a2messaging.[Parameters] ([Message]);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2messaging' and SEQUENCE_NAME=N'SQ_Environment')
	create sequence a2messaging.SQ_Environment as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2messaging' and TABLE_NAME=N'Environment')
begin
	create table a2messaging.[Environment]
	(
		Id	bigint	not null constraint PK_Environment primary key
			constraint Environment_PK default(next value for a2messaging.SQ_Environment),
		[Message] bigint not null
			constraint FK_Environment_Messages_Id references a2messaging.[Messages](Id),
		[Name] nvarchar(255) not null,
		[Value] nvarchar(255) not null
	);
end
go
------------------------------------------------
if not exists (select * from sys.indexes where object_id = object_id(N'a2messaging.Environment') and name = N'IX_MessagingEnvironment_Message')
	create nonclustered index IX_MessagingEnvironment_Message on a2messaging.[Environment] ([Message]);
go
------------------------------------------------
if not exists (select * from sys.indexes where object_id = object_id(N'a2messaging.Environment') and name = N'IX_MessagingEnvironment_Name')
	create nonclustered index IX_MessagingEnvironment_Name on a2messaging.[Environment] ([Name])
	include ([Message],[Value]);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2messaging' and TABLE_NAME=N'Log')
begin
	create table a2messaging.[Log]
	(
		Id	bigint not null identity(100, 1) constraint PK_Log primary key,
		UserId bigint not null
			constraint FK_Log_UserId_Users foreign key references a2security.Users(Id),
		EventTime	datetime not null
			constraint DF_Log_EventTime2 default(a2sys.fn_getCurrentDate()),
		Severity nchar(1) not null,
		[Message] nvarchar(max) null,
	);
end
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_Log_EventTime' and parent_object_id = object_id(N'a2messaging.Log'))
begin
	alter table a2messaging.[Log] drop constraint DF_Log_EventTime;
	alter table a2messaging.[Log] add constraint DF_Log_EventTime2 default(a2sys.fn_getCurrentDate()) for EventTime with values;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2messaging' and ROUTINE_NAME=N'WriteLog')
	drop procedure [a2messaging].[WriteLog]
go
------------------------------------------------
create procedure [a2messaging].[WriteLog]
	@UserId bigint = null,
	@Severity int,
	@Message nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	insert into a2messaging.[Log] (UserId, Severity, [Message]) 
		values (isnull(@UserId, 0 /*system user*/), char(@Severity), @Message);
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2messaging' and ROUTINE_NAME=N'Message.Queue.Metadata')
	drop procedure a2messaging.[Message.Queue.Metadata]
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2messaging' and ROUTINE_NAME=N'Message.Queue.Update')
	drop procedure a2messaging.[Message.Queue.Update]
go
------------------------------------------------
if exists (select * from sys.types st join sys.schemas ss ON st.schema_id = ss.schema_id where st.name = N'Message.TableType' AND ss.name = N'a2messaging')
	drop type a2messaging.[Message.TableType];
go
------------------------------------------------
if exists (select * from sys.types st join sys.schemas ss ON st.schema_id = ss.schema_id where st.name = N'NameValue.TableType' AND ss.name = N'a2messaging')
	drop type a2messaging.[NameValue.TableType];
go
------------------------------------------------
create type a2messaging.[Message.TableType] as
table (
	[Id] bigint null,
	[Template] nvarchar(255),
	[Key] nvarchar(255),
	[TargetId] bigint,
	[Source] nvarchar(255)
)
go
------------------------------------------------
create type a2messaging.[NameValue.TableType] as
table (
	[Name] nvarchar(255),
	[Value] nvarchar(max)
)
go
------------------------------------------------
create procedure a2messaging.[Message.Queue.Metadata]
as
begin
	set nocount on;
	declare @message a2messaging.[Message.TableType];
	declare @nv a2messaging.[NameValue.TableType];
	select [Message!Message!Metadata] = null, * from @message;
	select [Parameters!Message.Parameters!Metadata] = null, * from @nv;
	select [Environment!Message.Environment!Metadata] = null, * from @nv;
end
go
------------------------------------------------
create procedure a2messaging.[Message.Queue.Update]
@Message a2messaging.[Message.TableType] readonly,
@Parameters a2messaging.[NameValue.TableType] readonly,
@Environment a2messaging.[NameValue.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level serializable;
	set xact_abort on;
	declare @rt table(Id bigint);
	declare @msgid bigint;
	insert into a2messaging.[Messages] (Template, [Key], TargetId, [Source])
		output inserted.Id into @rt(Id)
		select Template, [Key], TargetId, [Source] from @Message;
	select top(1) @msgid = Id from @rt;
	insert into a2messaging.[Parameters] ([Message], [Name], [Value]) 
		select @msgid, [Name], [Value] from @Parameters;
	insert into a2messaging.Environment([Message], [Name], [Value]) 
		select @msgid, [Name], [Value] from @Environment;
	select [Result!TResult!Object] = null, Id=@msgid;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2messaging' and ROUTINE_NAME=N'Message.Queue.Load')
	drop procedure a2messaging.[Message.Queue.Load]
go
------------------------------------------------
create procedure a2messaging.[Message.Queue.Load]
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	select [Message!TMessage!Object] = null, [Id!!Id] = Id, [Template], [Key], TargetId,
		[Parameters!TNameValue!Array] = null, [Environment!TNameValue!Array] = null
	from a2messaging.[Messages] where Id=@Id;
	select [!TNameValue!Array] = null, [Name], [Value], [!TMessage.Parameters!ParentId] = [Message]
		from a2messaging.[Parameters] where [Message]=@Id;
	select [!TNameValue!Array] = null, [Name], [Value], [!TMessage.Environment!ParentId] = [Message]
		from a2messaging.[Environment] where [Message]=@Id;
end
go
------------------------------------------------
begin
	set nocount on;
	grant execute on schema ::a2messaging to public;
end
go


/*
Copyright © 2008-2021 Alex Kukhtin

Last updated : 20 jun 2021
module version : 7680
*/
------------------------------------------------
exec a2sys.SetVersion N'std:ui', 7680;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'a2ui')
begin
	exec sp_executesql N'create schema a2ui';
end
go
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2ui' and SEQUENCE_NAME=N'SQ_Menu')
	create sequence a2ui.SQ_Menu as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Menu')
begin
	create table a2ui.Menu
	(
		Id	bigint not null constraint PK_Menu primary key
			constraint DF_Menu_PK default(next value for a2ui.SQ_Menu),
		Parent bigint null
			constraint FK_Menu_Parent_Menu foreign key references a2ui.Menu(Id),
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
		[ClassName] nvarchar(255) null,
		[Module] nvarchar(16) null
			constraint FK_Menu_Module_Modules foreign key references a2security.Modules(Id)
	);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Menu' and COLUMN_NAME=N'Help')
	alter table a2ui.Menu add Help nvarchar(255) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Menu' and COLUMN_NAME=N'Key')
	alter table a2ui.Menu add [Key] nchar(4) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Menu' and COLUMN_NAME=N'Params')
	alter table a2ui.Menu add Params nvarchar(255) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Menu' and COLUMN_NAME=N'Feature')
	alter table a2ui.Menu add [Feature] nchar(4) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Menu' and COLUMN_NAME=N'Feature2')
	alter table a2ui.Menu add Feature2 nvarchar(255) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Menu' and COLUMN_NAME=N'ClassName')
	alter table a2ui.Menu add [ClassName] nvarchar(255) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Menu' and COLUMN_NAME=N'Module')
	alter table a2ui.Menu add [Module] nvarchar(16) null
			constraint FK_Menu_Module_Modules foreign key references a2security.Modules(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2security' and TABLE_NAME=N'Menu.Acl')
begin
	-- ACL for menu
	create table a2security.[Menu.Acl]
	(
		Menu bigint not null 
			constraint FK_MenuAcl_Menu foreign key references a2ui.Menu(Id),
		UserId bigint not null 
			constraint FK_MenuAcl_UserId_Users foreign key references a2security.Users(Id),
		CanView bit null,
		[Permissions] as cast(CanView as int)
		constraint PK_MenuAcl primary key(Menu, UserId)
	);
end
go
------------------------------------------------
if not exists (select * from sys.indexes where [name] = N'IX_MenuAcl_UserId')
	create nonclustered index IX_MenuAcl_UserId on a2security.[Menu.Acl] (UserId);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Feedback')
begin
	create table a2ui.Feedback
	(
		Id	bigint identity(1, 1) not null constraint PK_Feedback primary key,
		[Date] datetime not null
			constraint DF_Feedback_CurrentDate default(a2sys.fn_getCurrentDate()),
		UserId bigint not null
			constraint FK_Feedback_UserId_Users foreign key references a2security.Users(Id),
		[Text] nvarchar(max) null
	);
end
go
------------------------------------------------
if exists(select * from sys.default_constraints where name=N'DF_Feedback_UtcDate' and parent_object_id = object_id(N'a2ui.Feedback'))
begin
	alter table a2ui.Feedback drop constraint DF_Feedback_UtcDate;
	alter table a2ui.Feedback add constraint DF_Feedback_CurrentDate default(a2sys.fn_getCurrentDate()) for [Date];
end
go
------------------------------------------------
if (255 = (select CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2ui' and TABLE_NAME=N'Feedback' and COLUMN_NAME=N'Text'))
begin
	alter table a2ui.Feedback alter column [Text] nvarchar(max) null;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2ui' and ROUTINE_NAME=N'Menu.User.Load')
	drop procedure a2ui.[Menu.User.Load]
go
------------------------------------------------
create procedure a2ui.[Menu.User.Load]
@TenantId int = null,
@UserId bigint,
@Mobile bit = 0,
@Groups nvarchar(255) = null -- for use claims
as
begin
	set nocount on;
	declare @RootId bigint;
	set @RootId = 1;
	if @Mobile = 1
		set @RootId = 2;
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
		inner join a2security.[Menu.Acl] a on a.Menu = RT.Id
		inner join a2ui.Menu m on RT.Id=m.Id
	where a.UserId = @UserId and a.CanView = 1
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
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2ui' and ROUTINE_NAME=N'Menu.Module.User.Load')
	drop procedure a2ui.[Menu.Module.User.Load]
go
------------------------------------------------
create procedure a2ui.[Menu.Module.User.Load]
@TenantId int = null,
@UserId bigint,
@CompanyId bigint = null,
@Mobile bit = 0
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @isadmin bit;
	set @isadmin = a2security.fn_isUserAdmin(@UserId);

	declare @menutable table(Id bigint, [Level] int); 

	if @isadmin = 0
	begin
		-- all parents
		with P(Id, ParentId, [Level])
		as
		(
			select m.Id, m.Parent, 0
			from a2security.[Module.Acl] a inner join a2ui.Menu m on a.Module = m.Module
			where a.UserId = @UserId and a.CanView = 1
			union all
			select m.Id, m.Parent, [Level] - 1
				from a2ui.Menu m inner join P on m.Id=P.ParentId
		)
		insert into @menutable(Id)
		select Id from P group by Id;
	end

	declare @RootId bigint = 1;
	if @Mobile = 1
		set @RootId = 2;

	with RT as (
		select Id=m0.Id, ParentId = m0.Parent, Module, [Level]=0
			from a2ui.Menu m0
			where m0.Id = 1
		union all
		select m1.Id, m1.Parent, m1.Module, RT.[Level]+1
			from RT inner join a2ui.Menu m1 on m1.Parent = RT.Id
	)
	select [Menu!TMenu!Tree] = null, [Id!!Id]=RT.Id, [!TMenu.Menu!ParentId]=RT.ParentId,
		[Menu!TMenu!Array] = null,
		m.[Name], m.[Url], m.Icon, m.[Description], m.Help, m.ClassName
	from RT
		inner join a2ui.Menu m on RT.Id=m.Id
		left join @menutable mt on m.Id = mt.Id
	where @isadmin = 1 or mt.Id is not null
	order by RT.[Level], m.[Order], RT.[Id];

	-- companies
	exec a2security.[User.Companies] @UserId = @UserId;

	-- permissions
	select [Permissions!TPerm!Array] = null, [Module], [Permissions]
	from a2security.[Module.Acl] where UserId = @UserId;

	-- system parameters
	select [SysParams!TParam!Object]= null, [AppTitle], [AppSubTitle], [SideBarMode], [NavBarMode], [Pages]
	from (select [Name], [Value] = StringValue from a2sys.SysParams) as s
		pivot (min([Value]) for [Name] in ([AppTitle], [AppSubTitle], [SideBarMode], [NavBarMode], [Pages])) as p;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2ui' and ROUTINE_NAME=N'AppTitle.Load')
	drop procedure a2ui.[AppTitle.Load]
go
------------------------------------------------
create procedure a2ui.[AppTitle.Load]
as
begin
	set nocount on;
	select [AppTitle], [AppSubTitle]
	from (select Name, Value=StringValue from a2sys.SysParams) as s
		pivot (min(Value) for Name in ([AppTitle], [AppSubTitle])) as p;
end
go
-----------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2security.fn_GetMenuFor') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2security.fn_GetMenuFor;
go
------------------------------------------------
create function a2security.fn_GetMenuFor(@MenuId bigint)
returns @rettable table (Id bigint, Parent bit)
as
begin
	declare @tx table (Id bigint, Parent bit);

	-- all children
	with C(Id, ParentId)
	as
	(
		select @MenuId, cast(null as bigint) 
		union all
		select m.Id, m.Parent
			from a2ui.Menu m inner join C on m.Parent=C.Id
	)
	insert into @tx(Id, Parent)
		select Id, 0 from C
		group by Id;

	-- all parent 
	with P(Id, ParentId)
	as
	(
		select cast(null as bigint), @MenuId 
		union all
		select m.Id, m.Parent
			from a2ui.Menu m inner join P on m.Id=P.ParentId
	)
	insert into @tx(Id, Parent)
		select Id, 1 from P
		group by Id;

	insert into @rettable
		select Id, Parent from @tx
			where Id is not null
		group by Id, Parent;
	return;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.UpdateAcl.Menu')
	drop procedure [a2security].[Permission.UpdateAcl.Menu]
go
------------------------------------------------
create procedure [a2security].[Permission.UpdateAcl.Menu]
as
begin
	set nocount on;
	declare @MenuTable table (Id bigint, UserId bigint, GroupId bigint, CanView smallint);

	insert into @MenuTable (Id, UserId, GroupId, CanView)
		select f.Id, a.UserId, a.GroupId, a.CanView
		from a2security.Acl a 
			cross apply a2security.fn_GetMenuFor(a.ObjectId) f
			/*exclude denied parents */
		where a.[Object] = N'std:menu' and Not (Parent = 1 and CanView = -1)
		group by f.Id, UserId, GroupId, CanView;

	declare @UserTable table (ObjectId bigint, UserId bigint, CanView bit);

	with T(ObjectId, UserId, CanView)
	as
	(
		select a.Id, UserId=isnull(ur.UserId, a.UserId), a.CanView
		from @MenuTable a
		left join a2security.UserGroups ur on a.GroupId = ur.GroupId
		where isnull(ur.UserId, a.UserId) is not null
	)
	insert into @UserTable(ObjectId, UserId, CanView)
	select ObjectId, UserId,
		_CanView = isnull(case 
				when min(T.CanView) = -1 then 0
				when max(T.CanView) = 1 then 1
				end, 0)
	from T
	group by ObjectId, UserId;

	merge a2security.[Menu.Acl] as target
	using
	(
		select ObjectId, UserId, CanView
		from @UserTable T
		where CanView = 1
	) as source(ObjectId, UserId, CanView)
		on target.Menu = source.[ObjectId] and target.UserId=source.UserId
	when matched then
		update set 
			target.CanView = source.CanView
	when not matched by target then
		insert (Menu, UserId, CanView)
			values (source.[ObjectId], source.UserId, source.CanView)
	when not matched by source then
		delete;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2security' and ROUTINE_NAME=N'Permission.UpdateUserAcl.Menu')
	drop procedure [a2security].[Permission.UpdateUserAcl.Menu]
go
------------------------------------------------
create procedure [a2security].[Permission.UpdateUserAcl.Menu]
@UserId bigint
as
begin
	set nocount on;
	declare @MenuTable table (Id bigint, UserId bigint, GroupId bigint, CanView smallint);

	insert into @MenuTable (Id, UserId, GroupId, CanView)
		select f.Id, a.UserId, a.GroupId, a.CanView
		from a2security.Acl a 
			cross apply a2security.fn_GetMenuFor(a.ObjectId) f
			/*exclude denied parents */
		where a.[Object] = N'std:menu' and Not (Parent = 1 and CanView = -1)
		group by f.Id, UserId, GroupId, CanView;

	declare @UserTable table (ObjectId bigint, UserId bigint, CanView bit);

	with T(ObjectId, UserId, CanView)
	as
	(
		select a.Id, UserId=isnull(ur.UserId, a.UserId), a.CanView
		from @MenuTable a
		left join a2security.UserGroups ur on a.GroupId = ur.GroupId
		where isnull(ur.UserId, a.UserId) = @UserId
	)
	insert into @UserTable(ObjectId, UserId, CanView)
	select ObjectId, UserId,
		_CanView = isnull(case 
				when min(T.CanView) = -1 then 0
				when max(T.CanView) = 1 then 1
				end, 0)
	from T
	group by ObjectId, UserId;

	merge a2security.[Menu.Acl] as target
	using
	(
		select ObjectId, UserId, CanView
		from @UserTable T
		where CanView = 1
	) as source(ObjectId, UserId, CanView)
		on target.Menu = source.[ObjectId] and target.UserId=source.UserId
	when matched then
		update set 
			target.CanView = source.CanView
	when not matched by target then
		insert (Menu, UserId, CanView)
			values (source.[ObjectId], source.UserId, source.CanView)
	when not matched by source and target.UserId = @UserId then
		delete;
end
go
-----------------------------------------------
if exists (select * from sys.objects where object_id = object_id(N'a2security.fn_IsMenuVisible') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function a2security.fn_IsMenuVisible;
go
------------------------------------------------
create function a2security.fn_IsMenuVisible(@MenuId bigint, @UserId bigint)
returns bit
as
begin
	declare @result bit;
	select @result = case when CanView = 1 then 1 else 0 end from a2security.Acl where [Object] = N'std:menu' and ObjectId = @MenuId and UserId = @UserId;
	return isnull(@result, 1); -- not found - visible
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2ui' and ROUTINE_NAME=N'Menu.SetVisible')
	drop procedure a2ui.[Menu.SetVisible]
go
------------------------------------------------
create procedure a2ui.[Menu.SetVisible]
@UserId bigint,
@MenuId bigint,
@Visible bit
as
begin
	set nocount on;
	set transaction isolation level read committed;
	if @Visible = 0 and not exists(select * from a2security.Acl where [Object] = N'std:menu' and ObjectId = @MenuId and UserId = @UserId)
		 insert into a2security.Acl ([Object], ObjectId, UserId, CanView) values (N'std:menu', @MenuId, @UserId, -1);
	else if @Visible = 1
		delete from a2security.Acl where [Object] = N'std:menu' and ObjectId = @MenuId and UserId = @UserId;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA = N'a2ui' and DOMAIN_NAME = N'Menu2.TableType')
exec sp_executesql N'
create type a2ui.[Menu2.TableType] as table
(
	Id bigint,
	Parent bigint,
	[Key] nchar(4),
	[Feature] nchar(4),
	[Name] nvarchar(255),
	[Url] nvarchar(255),
	Icon nvarchar(255),
	[Model] nvarchar(255),
	[Order] int,
	[Description] nvarchar(255),
	[Help] nvarchar(255),
	Params nvarchar(255),
	Feature2 nvarchar(255)
)';
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA = N'a2ui' and DOMAIN_NAME = N'MenuModule.TableType')
exec sp_executesql N'
create type a2ui.[MenuModule.TableType] as table
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
)';
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2ui' and ROUTINE_NAME=N'Menu.Merge')
	drop procedure a2ui.[Menu.Merge]
go
------------------------------------------------
create procedure a2ui.[Menu.Merge]
@Menu a2ui.[Menu2.TableType] readonly,
@Start bigint,
@End bigint
as
begin
	with T as (
		select * from a2ui.Menu where Id >=@Start and Id <= @End
	)
	merge T as t
	using @Menu as s
	on t.Id = s.Id 
	when matched then
		update set
			t.Id = s.Id,
			t.Parent = s.Parent,
			t.[Key] = s.[Key],
			t.[Name] = s.[Name],
			t.[Url] = s.[Url],
			t.[Icon] = s.Icon,
			t.[Order] = s.[Order],
			t.Feature = s.Feature,
			t.Model = s.Model,
			t.[Description] = s.[Description],
			t.Help = s.Help,
			t.Params = s.Params
	when not matched by target then
		insert(Id, Parent, [Key], [Name], [Url], Icon, [Order], Feature, Model, [Description], Help, Params) values 
		(Id, Parent, [Key], [Name], [Url], Icon, [Order], Feature, Model, [Description], Help, Params)
	when not matched by source and t.Id >= @Start and t.Id < @End then 
		delete;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2ui' and ROUTINE_NAME=N'MenuModule.Merge')
	drop procedure a2ui.[MenuModule.Merge]
go
------------------------------------------------
create procedure a2ui.[MenuModule.Merge]
@Menu a2ui.[MenuModule.TableType] readonly,
@Start bigint,
@End bigint
as
begin
	with T as (
		select * from a2ui.Menu where Id >=@Start and Id <= @End
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
			t.Module = s.Module,
			t.ClassName = s.ClassName
	when not matched by target then
		insert(Id, Parent, [Name], [Url], Icon, [Order], Model, [Description], Help, Module, ClassName) values 
		(Id, Parent, [Name], [Url], Icon, [Order], Model, [Description], Help, Module, ClassName)
	when not matched by source and t.Id >= @Start and t.Id < @End then 
		delete;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2ui' and ROUTINE_NAME=N'SaveFeedback')
	drop procedure a2ui.SaveFeedback
go
------------------------------------------------
create procedure a2ui.SaveFeedback
@UserId bigint,
@Text nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	insert into a2ui.Feedback(UserId, [Text]) values (@UserId, @Text);
end
go
------------------------------------------------
begin
	set nocount on;
	grant execute on schema ::a2ui to public;
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
create or alter procedure appsec.[User.SetPasswordHash]
@UserId bigint,
@PasswordHash nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update appsec.ViewUsers set PasswordHash2 = @PasswordHash where Id=@UserId;
end
go
------------------------------------------------
create or alter procedure appsec.[User.SetSecurityStamp]
@UserId bigint,
@SecurityStamp nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update appsec.ViewUsers set SecurityStamp2 = @SecurityStamp where Id=@UserId;
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
------------------------------------------------
grant execute on schema::cat to public;
grant execute on schema::doc to public;
grant execute on schema::acc to public;
grant execute on schema::jrn to public;
grant execute on schema::usr to public;
grant execute on schema::rep to public;
grant execute on schema::ini to public;
grant execute on schema::ui to public;
grant execute on schema::app to public;
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
	[Role] bigint not null,
	Article nvarchar(32),
	Barcode nvarchar(32),
	Unit bigint, /* base, references cat.Units */
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	Vendor bigint, -- references cat.Vendors
	Brand bigint, -- references cat.Brands
	Country nchar(3), -- references cat.Countries
	[Uid] uniqueidentifier not null
		constraint DF_Items_Uid default(newid()),
	constraint PK_Items primary key (TenantId, Id),
	constraint FK_Items_Unit_Units foreign key (TenantId, Unit) references cat.Units(TenantId, Id),
	constraint FK_Items_Vendor_Vendors foreign key (TenantId, Vendor) references cat.Vendors(TenantId, Id),
	constraint FK_Items_Brand_Brands foreign key (TenantId, Brand) references cat.Brands(TenantId, Id),
	constraint FK_Items_Role_ItemRoles foreign key (TenantId, [Role]) references cat.ItemRoles(TenantId, Id),
	constraint FK_Items_Country_Countries foreign key (TenantId, Country) references cat.Countries(TenantId, Code)
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
		constraint DF_Agents_Id default(next value for cat.SQ_Agents),
	Void bit not null 
		constraint DF_Agents_Void default(0),
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
		constraint PK_Agents primary key (TenantId, Id),
	[Partner] bit,
	[Person] bit,
	-- roles
	IsSupplier bit,
	IsCustomer bit
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
	[Agent] nchar(1), -- TODO: Delete
	Form nvarchar(16) not null,
	[DocumentUrl] nvarchar(255) null,
	[WarehouseFrom] nchar(1), -- TODO: Delete
	[WarehouseTo] nchar(1), -- TODO: Delete
	[Uid] uniqueidentifier not null
		constraint DF_Operations_Uid default(newid()),
	constraint PK_Operations primary key (TenantId, Id),
	constraint FK_Operations_Form_Forms foreign key (TenantId, Form) references doc.Forms(TenantId, Id)
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
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_OpJournalStore')
	create sequence doc.SQ_OpJournalStore as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpJournalStore')
create table doc.OpJournalStore
(
	TenantId int not null,
	Id bigint not null
		constraint DF_OpJournalStore_Id default(next value for doc.SQ_OpJournalStore),
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

	constraint PK_OpTrans primary key (TenantId, Id, Operation),
	constraint FK_OpTrans_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id),
	constraint FK_OpTrans_Plan_Accounts foreign key (TenantId, [Plan]) references acc.Accounts(TenantId, Id),
	constraint FK_OpTrans_Dt_Accounts foreign key (TenantId, [Dt]) references acc.Accounts(TenantId, Id),
	constraint FK_OpTrans_Ct_Accounts foreign key (TenantId, [Ct]) references acc.Accounts(TenantId, Id),
	constraint FK_OpTrans_DtAccKind_ItemRoles foreign key (TenantId, DtAccKind) references acc.AccKinds(TenantId, Id),
	constraint FK_OpTrans_CtAccKind_ItemRoles foreign key (TenantId, CtAccKind) references acc.AccKinds(TenantId, Id),
);
go
/*
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_OpSimple')
	create sequence doc.SQ_OpSimple as bigint start with 1000 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpSimple')
create table doc.OpSimple
(
	TenantId int not null,
	Id bigint not null
		constraint DF_OpSimple_Id default(next value for doc.SQ_OpSimple),
	Operation bigint not null,
	RowNo int,
	RowKind nvarchar(16) not null,
	[Uid] uniqueidentifier not null
		constraint DF_OpSimple_Uid default(newid()),
	constraint PK_OpSimple primary key (TenantId, Id, Operation),
	constraint FK_OpSimple_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id)
);
go
*/
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
	[SNo] nvarchar(64),
	Done bit not null
		constraint DF_Documents_Done default(0),
	Temp bit not null
		constraint DF_Documents_Temp default(0),
	[Parent] bigint,
	[Base] bigint,
	OpLink bigint,
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
	constraint FK_Documents_ItemRole_ItemRoles foreign key (TenantId, ItemRole) references cat.ItemRoles(TenantId, Id)
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
	Detail bigint,
	InOut smallint not null,
	Company bigint not null,
	Agent bigint null,
	[Contract] bigint null,
	CashAccount bigint not null,
	CashFlowItem bigint null,
	RespCenter bigint null,
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
		constraint FK_CashJournal_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id)
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
		constraint DF_Journal_Id default(next value for jrn.SQ_Journal),
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
	[Contract] bigint null,
	Item bigint null,
	CashAccount bigint null,
	CostItem bigint null,
	CashFlowItem bigint null,
	RespCenter bigint null,
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
		constraint FK_Journal_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id)
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

-- MIGRATIONS
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations' and COLUMN_NAME=N'DocumentUrl')
	alter table doc.Operations add DocumentUrl nvarchar(255) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Forms' and COLUMN_NAME=N'Url')
	alter table doc.Forms add [Url] nvarchar(255);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'DocDetails' and COLUMN_NAME=N'FQty')
	alter table doc.DocDetails add FQty float not null
		constraint DF_DocDetails_FQty default(0) with values;
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
	insert into a2sys.SysParams ([Name], StringValue) values (N'AppTitle', N'Нова Ера');
else
	update a2sys.SysParams set StringValue = N'Нова Ера' where [Name] = N'AppTitle';
go
------------------------------------------------
create or alter procedure a2ui.[Menu.Simple.User.Load]
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
			from a2ui.Menu m0
			where m0.Id = @Root
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
		(2,  null,  0, N'Start',         null,         null, null),
		(3,  null,  0, N'Init',      null,         null, null),

		(71,    2,  1, N'@[Welcome]',     N'appstart',   N'success-outline', null),
		(72,    3,  1, N'@[AppInit]',     N'appinit',    N'arrow-up', null),

		(10,    1,  10, N'@[Dashboard]',     N'dashboard',   N'dashboard-outline', null),
		(11,    1,  11, N'@[Crm]',           N'crm',         N'share', null),
		(12,    1,  12, N'@[Sales]',         N'sales',       N'shopping', N'border-top'),
		(13,    1,  13, N'@[Purchases]',     N'purchase',    N'cart', null),
		--(14,    1,  14, N'@[Manufacturing]', N'manufacturing',  N'wrench', null),
		(15,    1,  15, N'@[Accounting]',    N'accounting',  N'calc', null),
		--(16,    1,  16, N'@[Payroll]',       N'payroll',  N'calc', null),
		--(17,    1,  17, N'@[Tax]',           N'tax',  N'calc', null),
		(88,    1,  88, N'@[Settings]',       N'settings',  N'gear-outline', N'border-top'),
		(90,    1,  90, N'@[Profile]',        N'profile',   N'user', null),
		-- CRM
		(1101,  11, 11, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', null),
		--(1102,  11, 12, N'@[Leads]',          N'lead',      N'users', N'border-top'),
		-- Sales
		(1201,   12, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(120,    12, 11, N'@[Documents]',      null,  null, null),
		(1202,   120, 2, N'@[Orders]',         N'order',     N'task-complete', null),
		(1203,   120, 3, N'@[Sales]',          N'sales',     N'shopping', null),
		(1204,   120, 4, N'@[Payment]',        N'payment',   N'currency-uah', null),
		(121,    12, 12, N'@[PriceLists]', null, null, null),
		(1210,	 121, 11, N'@[Prices]',         N'price',     N'tag-outline', null),
		(122,    12, 12, N'@[Catalogs]',      null,  null, null),
		(1220,   122, 30, N'@[Customers]',      N'agent',     N'users', null),
		(1221,   122, 31, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1223,   122, 32, N'@[Items]',          N'item',      N'package-outline', N'line-top'),
		(1224,   122, 33, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1230,   12, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1231,   12, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Purchase
		(1301,   13, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(130,    13, 11, N'@[Documents]',      null,  null, null),
		(1302,  130, 10, N'@[Purchases]',      N'purchase',  N'cart', null),
		(1303,  130, 11, N'@[Warehouse]',      N'stock',     N'warehouse', null),
		(1304,  130, 12, N'@[Payment]',        N'payment',   N'currency-uah', null),
		--(1310,   13, 20, N'@[Planning]',       N'plan',      N'calendar', N'border-top'),
		--(131,    13, 12, N'@[Prices]', null, null, null),
		--(1311,  131, 10, N'@[PriceDoc]',       N'pricedoc',  N'file', null),
		--(1312,  131, 11, N'@[Prices]',         N'price',     N'tag-outline', null),
		(133,    13, 14, N'@[Catalogs]',  null, null, null),
		(1320,  133, 10, N'@[Suppliers]',      N'agent',     N'users', null),
		(1321,  133, 11, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1322,  133, 12, N'@[Items]',          N'item',      N'package-outline', N'line-top'),
		(1323,  133, 13, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1330,   13, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1331,   13, 41, N'@[Service]',        N'service',   N'gear-outline', null),
		-- Accounting
		(1501,   15, 10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(150,    15, 11, N'@[Documents]',      null, null, null),
		(1502,  150, 10, N'@[Bank]',           N'bank',   N'bank',  null),
		(1503,  150, 11, N'@[CashAccount]',    N'cash',   N'currency-uah',  null),
		(1504,   15, 12, N'@[AccountPlans]',   N'plan',      N'account',  N'border-top'),
		(153,    15, 15, N'@[Catalogs]',  null, null, null),
		(1505,  153, 10, N'@[BankAccounts]',   N'bankacc',   N'bank', null),
		(1506,	153, 11, N'@[CashAccounts]',   N'cashacc',   N'currency-uah', null),
		(1507,  153, 12, N'@[Agents]',         N'agent',     N'users', null),
		(1508,  153, 13, N'@[Persons]',        N'person',    N'user-role', null),
		(1509,  153, 14, N'@[Contracts]',      N'contract',  N'user-image', null),
		(1510,  153, 15, N'@[CatalogOther]',   N'catalog',   N'list', null),
		(1511,   15, 20, N'@[Journal]',        N'journal',   N'file-content',  N'border-top'),
		(1530,   15, 40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		(1531,   15, 41, N'@[Service]',        N'service',   N'gear-outline', null),

		-- Settings
		(880,   88, 10, N'@[Dashboard]',    'dashboard', 'dashboard-outline', N'border-bottom'),
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
		(8828, 882, 18, N'@[Items]',        N'item',      N'package-outline', N'line-top'),
		(8829, 882, 19, N'@[CatalogOther]', N'catalog',   N'list', null),
		(883,   88, 13, N'@[Administration]', null, null, null),
		(8830, 883, 16, N'@[Users]',        N'user',    N'user',  null),
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
	(102, N'Sales', 11, N'@[Items]', N'@[Grouping.Item]', N'/catalog/itemgroup/index', N'list',  N''),
	--(102, N'Sales', 12, N'@[Items]', N'@[Brands]',   N'/catalog/brand/index', N'list',  N''),
	(105, N'Sales', 11, N'@[Prices]', N'@[PriceKinds]',        N'/catalog/pricekind/index', N'list',  N''),

	(200, N'Purchase',   10, N'@[Items]',  N'@[Units]',        N'/catalog/unit/index', N'list',  N''),
	(201, N'Purchase',   11, N'@[Items]',  N'@[Grouping.Item]', N'/catalog/itemgroup/index', N'list',  N''),
	(202, N'Purchase',   12, N'@[Prices]', N'@[PriceKinds]',   N'/catalog/pricekind/index', N'list',  N''),

	-- accounting
	(300, N'Accounting', 10, N'@[Accounting]', N'@[Banks]', N'/catalog/bank/index', N'list',  N''),
	(301, N'Accounting', 11, N'@[Accounting]', N'@[Currencies]', N'/catalog/currency/index', N'list',  N''),
	(305, N'Accounting',  12, N'@[Items]',     N'@[Units]',      N'/catalog/unit/index', N'list',  N''),
	(306, N'Accounting',  13, N'@[Prices]',    N'@[PriceKinds]', N'/catalog/pricekind/index', N'list',  N''),

	-- settings
	(900, N'Settings',  01, N'@[General]',   N'@[Countries]',   N'/catalog/country/index', N'list',  N''),
	(901, N'Settings',  02, N'@[General]',   N'@[RespCenters]', N'/catalog/respcenter/index', N'list',  N''),
	(910, N'Settings',  10, N'@[Accounts]',  N'@[ItemRoles]',   N'/catalog/itemrole/index', N'list',  N''),
	(911, N'Settings',  11, N'@[Accounts]',  N'@[AccKinds]',    N'/catalog/acckind/index', N'list',  N''),
	(920, N'Settings',  21, N'@[Accounting]', N'@[Banks]',         N'/catalog/bank/index', N'list',  N''),
	(921, N'Settings',  22, N'@[Accounting]', N'@[Currencies]',    N'/catalog/currency/index', N'list',  N''),
	(922, N'Settings',  23, N'@[Accounting]', N'@[CostItems]',     N'/catalog/costitem/index', N'list',  N''),
	(923, N'Settings',  24, N'@[Accounting]', N'@[CashFlowItems]', N'/catalog/cashflowitem/index', N'list',  N''),
	(931, N'Settings',  31, N'@[Items]',  N'@[Grouping.Item]',     N'/catalog/itemgroup/index', N'list',  N''),
	(932, N'Settings',  32, N'@[Items]',  N'@[Categories]',        N'/catalog/itemcategory/index', N'list',  N''),
	(933, N'Settings',  33, N'@[Items]',  N'@[Units]',             N'/catalog/unit/index', N'list',  N''),
	(934, N'Settings',  34, N'@[Items]',  N'@[Brands]',            N'/catalog/brand/index', N'list',  N''),
	(945, N'Settings',  35, N'@[Items]',  N'@[Vendors]',           N'/catalog/vendor/index', N'list',  N''),
	(940, N'Settings',  40, N'@[Prices]', N'@[PriceKinds]',        N'/catalog/pricekind/index', N'list',  N'');

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
	Memo nvarchar(32),
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
		select Id = -@Group, 2, [Name] = N'@[WithoutGroup]', 0, Icon=N'ban'
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
	select [!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], 
		i.Article, i.Barcode, i.Memo, [Role!TItemRole!RefId] = i.[Role],
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short
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
	where i.TenantId = @TenantId and i.Void = 0
		and (@Id = -1 or @Id = ite.Parent or (@Id < 0 and i.Id not in (
			select Item from cat.ItemTreeElems intbl where intbl.TenantId = @TenantId and intbl.[Root] = -@Id /*hack:negative*/
		)))
		and (@fr is null or [Name] like @fr or Memo like @fr or Article like @fr or Barcode like @fr)
	group by i.Id, i.Unit, i.[Name], i.Article, i.Barcode, i.Memo, i.[Role]
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

	select [Elements!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], 
		i.Article, i.Barcode, i.Memo, [Role!TItemRole!RefId] = i.[Role],
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
		[!!RowCount]  = t.rowcnt
	from @items t inner join cat.Items i on i.TenantId = @TenantId and i.Id = t.id
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	order by t.rowno;

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
		[Role!TItemRole!RefId] = i.[Role],
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
		[Brand!TBrand!RefId] = i.Brand, [Vendor!TVendor!RefId] = i.Vendor,
		[Country!TCountry!RefId] = i.Country
	from cat.Items i 
		left join cat.Units u on  i.TenantId = u.TenantId and i.Unit = u.Id
	where i.TenantId = @TenantId and i.Id=@Id and i.Void = 0;

	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[Elements!THieElem!Array] = null
	from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id = [Root] and Id <> 0;

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
		[CostItem.Id!TCostItem!Id] = ir.CostItem, [CostItem.Name!TCostItem!Name] = ci.[Name]
	from cat.ItemRoles ir 
		left join cat.CostItems ci on ir.TenantId = ci.TenantId and ir.CostItem =ci.Id
	where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Item';
	
	select [!THieElem!Array] = null, [!THie.Elements!ParentId] = iti.[Root],
		[Group] = iti.Parent,
		[Path] = cat.fn_GetItemBreadcrumbs(@TenantId, iti.Parent, null)
	from cat.ItemTreeElems iti 
	where TenantId = @TenantId  and iti.Item = @Id;
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
	select [Groups!Item.Hierarchies.Elements!Metadata] = null, * from @Groups;
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
	when not matched by source and t.TenantId=@TenantId and t.Item = @RetId then delete;

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
		and (@stock is null or ir.IsStock = @stock)
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
	declare @Group [GroupItem.TableType];
	select [Group!Group!Metadata] = null, * from @Group;
end
go
-------------------------------------------------
create or alter procedure cat.[HierarchyItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Group [GroupItem.TableType];
	select [Group!Group!Metadata] = null, * from @Group;
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Update]
@TenantId int = 1,
@UserId bigint,
@Group [GroupItem.TableType] readonly,
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
@Group [GroupItem.TableType] readonly,
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
	where TenantId = @TenantId and [Partner] = 1
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
		FullName, [Memo], IsSupplier, IsCustomer
	from cat.Agents a
	where TenantId = @TenantId and Id = @Id and [Partner] = 1;
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
	[Memo] nvarchar(255),
	IsCustomer bit,
	IsSupplier bit
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
		t.[FullName] = s.[FullName],
		t.IsCustomer = s.IsCustomer,
		t.IsSupplier = s.IsSupplier,
		t.[Partner] = 1
	when not matched by target then insert
		(TenantId, [Name], FullName, Memo, IsCustomer, IsSupplier, [Partner]) values
		(@TenantId, s.[Name], s.FullName, s.Memo, s.IsCustomer, s.IsSupplier, 1)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
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

	declare @cnts table(rowno int identity(1, 1), id bigint, agent bigint, 
		comp bigint, pkind bigint, kind nvarchar(16), rowcnt int);

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
	with T as (select agent from @cnts group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with T as (select comp from @cnts group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	with T as (select pkind from @cnts group by pkind)
	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk 
		inner join T t on pk.TenantId = @TenantId and pk.Id = pkind;

	with T as (select kind from @cnts group by kind)
	select [!TContractKind!Map] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from doc.ContractKinds ck 
		inner join T t on ck.TenantId = @TenantId and ck.Id = kind;

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

	insert into @ba(id, comp, bank, crc, rowcnt)
	select b.Id, b.Company, b.Bank, b.Currency, 
		count(*) over ()
	from cat.CashAccounts b
	where TenantId = @TenantId and b.IsCashAccount = 0 
		and (@Company is null or b.Company = @Company)
		and (@fr is null or b.[Name] like @fr or b.Memo like @fr)
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

	with TB as (
		select Id = t.id, [Sum] = sum(cj.[Sum] * cj.InOut)
		from @ba t inner join jrn.CashJournal cj on cj.TenantId = @TenantId and cj.CashAccount = t.id
		group by t.id
	)
	update @ba set balance = [Sum]
	from @ba t inner join TB on t.id = TB.Id;

	select [BankAccounts!TBankAccount!Array] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo, Balance = t.balance,
		[Company!TCompany!RefId] = ba.Company,
		[Currency!TCurrency!RefId] = ba.Currency,
		[ItemRole!TItemRole!RefId] = ba.ItemRole,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.CashAccounts ba on t.id  = ba.Id and ba.TenantId = @TenantId
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

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
		[ItemRole!TItemRole!RefId] = ba.ItemRole
	from cat.CashAccounts ba
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
		[Bank!TBank!RefId] = ba.Bank, [ItemRole!TItemRole!RefId] = ba.ItemRole
	from cat.CashAccounts ba
	where TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join cat.CashAccounts ba on c.TenantId = ba.TenantId and ba.Company = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, c.Short, c.Alpha3
	from cat.Currencies c inner join cat.CashAccounts ba on c.TenantId = ba.TenantId and ba.Currency = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

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

	insert into @ba(id, comp, crc, rowcnt)
	select c.Id, c.Company, c.Currency, 
		count(*) over ()
	from cat.CashAccounts c
	where TenantId = @TenantId
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

	with TB as (
		select Id = t.id, [Sum] = sum(cj.[Sum] * cj.InOut)
		from @ba t inner join jrn.CashJournal cj on cj.TenantId = @TenantId and cj.CashAccount = t.id
		group by t.id
	)
	update @ba set balance = [Sum]
	from @ba t inner join TB on t.id = TB.Id;

	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo, Balance = t.balance,
		[Company!TCompany!RefId] = ca.Company,
		[Currency!TCurrency!RefId] = ca.Currency,
		[ItemRole!TItemRole!RefId] = ca.ItemRole,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.CashAccounts ca on t.id  = ca.Id and ca.TenantId = @TenantId and ca.IsCashAccount = 1
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

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
@Mode nvarchar(16) = N'Cash',
@Date date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	with TB as (
		select Balance = sum([Sum] * InOut), CashAccount from jrn.CashJournal
		where [Date] <= @Date and TenantId = @TenantId
		group by CashAccount
	)
	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo, TB.Balance,
		[ItemRole!TItemRole!RefId] = ca.ItemRole
	from cat.CashAccounts ca
		left join TB on ca.Id = TB.CashAccount
	where ca.TenantId = @TenantId and ca.Company = @Company and 
		(@Mode = N'All' or @Mode = N'Cash' and ca.IsCashAccount = 1 or @Mode = N'Bank' and ca.IsCashAccount = 0);

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money';

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
		[Currency!TCurrency!RefId] = ca.Currency,
		[ItemRole!TItemRole!RefId] = ca.ItemRole
	from cat.CashAccounts ca
	where TenantId = @TenantId and ca.Id = @Id and ca.IsCashAccount = 1;

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
create or alter procedure cat.[CashAccount.GetRem]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Date date
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Result!TResult!Object] = null, Balance = rep.fn_getCashAccountRem(@TenantId, @Id, @Date)
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
	order by ir.Id;
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
		inner join T t on t.Id = b.Id
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

	select [!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form
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
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form
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
		[Items!TAccount!Items] = null, [!TAccount.Items!ParentId] = T.Parent
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

	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form!TForm!RefId] = o.Form,
		[Journals!TOpJournal!Array] = null
	from doc.Operations o
		inner join doc.Forms df on o.TenantId = df.TenantId and o.Form = df.Id
	where o.TenantId = @TenantId
	order by df.[Order], o.Id;

	select [Forms!TForm!Array] = null, [Id!!Id] = f.Id, [Name!!Name] = f.[Name], f.Category
	from doc.Forms f;
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
		o.DocumentUrl, [Form!TForm!RefId] = o.Form, 
		--[STrans!TSTrans!Array] = null,
		[OpLinks!TOpLink!Array] = null,
		[Trans!TOpTrans!Array] = null
	from doc.Operations o
	where o.TenantId = @TenantId and o.Id=@Id;

	/*
	-- SIMPLE TRANSACTIONS
	select [!TSTrans!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		[!TOperation.STrans!ParentId] = os.Operation
	from doc.OpSimple os 
	where os.TenantId = @TenantId and os.Operation = @Id;
	*/

	-- ACCOUNT TRANSACTIONS
	select [!TOpTrans!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		[Plan!TAccount!RefId] = [Plan], [Dt!TAccount!RefId] = Dt, [Ct!TAccount!RefId] = Ct, 
		DtAccMode, DtSum, DtRow, CtAccMode, CtSum, CtRow,
		[!TOperation.Trans!ParentId] = ot.Operation,
		[DtAccKind!TAccKind!RefId] = ot.DtAccKind, [CtAccKind!TAccKind!RefId] = ot.CtAccKind
	from doc.OpTrans ot 
	where ot.TenantId = @TenantId and ot.Operation = @Id
	order by ot.Id;

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

	select [!TRowKind!Array] = null, [Id!!Id] = rk.Id, [Name!!Name] = rk.[Name], [!TForm.RowKinds!ParentId] = rk.Form
	from doc.FormRowKinds rk where rk.TenantId = @TenantId
	order by rk.[Order];

	select [AccountKinds!TAccKind!Array] = null, [Id!!Id] = ak.Id, [Name!!Name] = ak.[Name]
	from acc.AccKinds ak
	where ak.TenantId = @TenantId
	order by ak.Id;
end
go
-------------------------------------------------
drop procedure if exists doc.[Operation.Metadata];
drop procedure if exists doc.[Operation.Update];
drop type if exists doc.[Operation.TableType];
drop type if exists doc.[OpJournalStore.TableType];
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
	DtAccKind bigint,
	DtRow nchar(1),
	DtSum nchar(1),
	CtAccMode nchar(1),
	CtAccKind bigint,
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
	declare @OpPrintForm doc.[OpPrintForm.TableType];
	declare @OpLinks doc.[OpLink.TableType];
	select [Operation!Operation!Metadata] = null, * from @Operation;
	select [JournalStore!Operation.JournalStore!Metadata] = null, * from @JournalStore;
	select [Trans!Operation.Trans!Metadata] = null, * from @OpTrans;
	select [Menu!Menu!Metadata] = null, * from @OpMenu;
	select [PrintForms!PrintForms!Metadata] = null, * from @OpPrintForm;
	select [Links!Operation.OpLinks!Metadata] = null, * from @OpLinks;
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
		t.[DocumentUrl] = s.[DocumentUrl]
	when not matched by target then insert
		(TenantId, [Name], Form, Memo, DocumentUrl) values
		(@TenantId, s.[Name], s.Form, s.Memo, s.DocumentUrl)
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
		t.DtAccKind = s.DtAccKind,
		t.CtAccMode = s.CtAccMode,
		t.CtAccKind = s.CtAccKind,
		t.DtRow = s.DtRow,
		t.CtRow = s.CtRow,
		t.DtSum = s.DtSum,
		t.CtSum = s.CtSum
	when not matched by target then insert
		(TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct, DtAccMode, DtAccKind, CtAccMode, CtAccKind, 
			DtRow, CtRow, DtSum, CtSum) values
		(@TenantId, @Id, RowNo, isnull(RowKind, N''), s.[Plan], s.Dt, s.Ct, s.DtAccMode, s.DtAccKind, s.CtAccMode, s.CtAccKind, 
			s.DtRow, s.CtRow, s.DtSum, s.CtSum)
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

	exec doc.[Operation.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, @UserId = @UserId,
		@Id = @Id;
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

	select [LinkedDocs!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done],
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Parent
	from doc.Documents d 
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Parent = @Id;

	select [!TDocBase!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], d.[Done],
		[OpName] = o.[Name], o.Form, o.DocumentUrl
	from doc.Documents p inner join doc.Documents d on d.TenantId = p.TenantId and d.Parent = p.Id
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

	delete from doc.DocDetails from
		doc.DocDetails dd inner join doc.Documents d on dd.TenantId = d.TenantId and  dd.Document = d.Id
			where d.TenantId = @TenantId and d.UserCreated = @UserId and d.Temp = 1 and [Date] < dateadd(day, 1, getdate());
	delete from doc.Documents where TenantId = @TenantId and UserCreated = @UserId and Temp = 1
		and [Date] < dateadd(day, 1, getdate());
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
		comp bigint, whfrom bigint, whto bigint, rowcnt int);

	insert into @docs(id, op, agent, comp, whfrom, whto, rowcnt)
	select d.Id, d.Operation, d.Agent, d.Company, d.WhFrom, d.WhTo,
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
				when N'no' then d.[SNo]
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
				when N'no' then d.[SNo]
				when N'memo' then d.[Memo]
			end
		end desc,
		Id desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.SNo,
		d.Notice, d.Done,
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

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.SNo, d.Notice, d.[Sum], d.Done,
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, [WhFrom!TWarehouse!RefId] = d.WhFrom,
		[WhTo!TWarehouse!RefId] = d.WhTo, [Contract!TContract!RefId] = d.[Contract], 
		[PriceKind!TPriceKind!RefId] = d.PriceKind, [RespCenter!TRespCenter!RefId] = d.RespCenter,
		[CostItem!TCostItem!RefId] = d.CostItem, [ItemRole!TItemRole!RefId] = d.ItemRole,
		[StockRows!TRow!Array] = null,
		[ServiceRows!TRow!Array] = null,
		[ParentDoc!TDocBase!RefId] = d.Parent,
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
drop procedure if exists doc.[Document.Stock.Metadata];
drop procedure if exists doc.[Document.Stock.Update];
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
	Operation bigint,
	Agent bigint,
	Company bigint,
	WhFrom bigint,
	WhTo bigint,
	[Contract] bigint,
	PriceKind bigint,
	RespCenter bigint,
	CostItem bigint,
	ItemRole bigint,
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

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Apply for xml auto);
	throw 60000, @xml, 0;
	*/

	declare @rtable table(id bigint);
	declare @id bigint;

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
		t.CostItem = s.CostItem,
		t.ItemRole = s.ItemRole,
		t.Memo = s.Memo,
		t.SNo = s.SNo
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, WhFrom, WhTo, [Contract], 
			PriceKind, RespCenter, CostItem, ItemRole, Memo, SNo, UserCreated) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, WhFrom, s.WhTo, s.[Contract], 
			s.PriceKind, s.RespCenter, s.CostItem, s.ItemRole, s.Memo, s.SNo, @UserId)
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

	exec doc.[Document.DeleteTemp] @TenantId = @TenantId, @UserId = @UserId;

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
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo], d.[Notice], d.Done,
		[Operation!TOperation!RefId] = d.Operation, 
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

	-- menu
	select [Menu!TMenu!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], FormId = f.Id, FormName = f.[Name],
		o.DocumentUrl
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

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.Notice, d.[Sum], d.Done,
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, 
		[CashAccFrom!TCashAccount!RefId] = d.CashAccFrom, [CashAccTo!TCashAccount!RefId] = d.CashAccTo,
		[Contract!TContract!RefId] = d.[Contract], [CashFlowItem!TCashFlowItem!RefId] = d.CashFlowItem,
		[RespCenter!TRespCenter!RefId] = d.RespCenter, [ItemRole!TItemRole!RefId] = d.ItemRole,
		[ParentDoc!TDocBase!RefId] = d.Parent,
		[LinkedDocs!TDocBase!LazyArray] = null
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o 
		left join doc.Documents d on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.Id = @Id and d.TenantId = @TenantId;

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
	ItemRole bigint
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
		t.Memo = s.Memo,
		t.Notice = s.Notice,
		t.ItemRole = s.ItemRole
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Company, Agent, 
			CashAccFrom, CashAccTo, [Contract], CashFlowItem, RespCenter, Memo, Notice, ItemRole, UserCreated) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Company, s.Agent, 
			s.CashAccFrom, s.CashAccTo, s.[Contract], s.CashFlowItem, s.RespCenter, s.Memo, s.Notice, s.ItemRole, @UserId)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	exec doc.[Document.Pay.Load] @TenantId = @TenantId, 
	@UserId = @UserId, @Id = @id;
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
		[Contract] bigint, CashFlowItem bigint, RespCenter bigint,
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
			TrNo = ot.RowNo, dd.[RowNo], Detail = dd.Id, dd.[Item], Qty, dd.[Sum], dd.ESum,
			[Plan] = ot.[Plan], DtRow = isnull(ot.DtRow, N''), CtRow = isnull(ot.CtRow, N''),
			DtSum = isnull(ot.DtSum, N''), CtSum = isnull(ot.CtSum, N''),
			d.[Date], d.Agent, d.Company, d.RespCenter, dd.CostItem, d.WhFrom, d.WhTo, d.CashAccFrom, d.CashAccTo,
			d.[Contract], d.[CashFlowItem]
		from doc.DocDetails dd
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join doc.OpTrans ot on dd.TenantId = ot.TenantId and (dd.Kind = ot.RowKind or ot.RowKind = N'All')
			left join cat.ItemRoleAccounts ird on ird.TenantId = dd.TenantId and ird.[Role] = isnull(dd.ItemRoleTo, dd.ItemRole) and ird.AccKind = ot.DtAccKind
			left join cat.ItemRoleAccounts irc on irc.TenantId = dd.TenantId and irc.[Role] = dd.ItemRole and irc.AccKind = ot.CtAccKind
			left join cat.ItemRoleAccounts irdocdt on irdocdt.TenantId = d.TenantId and irdocdt.[Role] = d.ItemRole and irdocdt.AccKind = ot.DtAccKind
			left join cat.ItemRoleAccounts irdocct on irdocct.TenantId = d.TenantId and irdocct.[Role] = d.ItemRole and irdocct.AccKind = ot.CtAccKind
		where dd.TenantId = @TenantId and dd.Document = @Id and ot.Operation = @Operation 
			and (@exclude = 0 or Kind <> N'Service')
			--and (ot.DtRow = N'R' or ot.CtRow = N'R')
	)
	insert into @trans(TrNo, RowNo, DtCt, Acc, CorrAcc, [Plan], [Detail], Item, RowMode, Wh, CashAcc, 
		[Date], Agent, Company, RespCenter, CostItem, [Contract],  CashFlowItem, Qty,[Sum], ESum, SumMode, CostSum, ResultSum)

	select TrNo, RowNo, DtCt = 1, Acc = Dt, CorrAcc = Ct, [Plan], Detail, Item, RowMode = DtRow, Wh = WhTo, CashAcc = CashAccTo,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, [Qty], [Sum], ESum, SumMode = DtSum, CostSum = 0, ResultSum = [Sum]
		from TR
	union all 
	select TrNo, RowNo, DtCt = -1, Acc = Ct, CorrAcc = Dt, [Plan], Detail, Item, RowMode = CtRow, Wh = WhFrom, CashAcc = CashAccFrom,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, [Qty], [Sum], ESum, SumMode = CtSum, CostSum = 0, ResultSum = [Sum]
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
	
	insert into jrn.Journal(TenantId, Document, Detail, TrNo, RowNo, [Date], DtCt, [Plan], Account, CorrAccount, [Sum], [Qty], [Item],
		Company, Agent, Warehouse, CashAccount, [Contract], CashFlowItem, CostItem, RespCenter)
	select TenantId = @TenantId, Document = @Id, Detail = iif(RowMode = N'R', Detail, null), TrNo, RowNo = iif(RowMode = N'R', RowNo, null),
		[Date], DtCt, [Plan], Acc, CorrAcc, [Sum] = sum([ResultSum]), Qty = sum(iif(RowMode = N'R', Qty, 0)),
		Item = iif(RowMode = N'R', Item, null),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter
	from @trans
	group by TrNo, 
		iif(RowMode = N'R', RowNo, null),
		[Date], DtCt, [Plan], Acc, CorrAcc, 
		iif(RowMode = N'R', Item, null),
		iif(RowMode = N'R', Detail, null),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, 
		CostItem, RespCenter
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
		[Contract] bigint, CashFlowItem bigint, [Sum] money);

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
			TrNo = ot.RowNo, d.[Sum],
			[Plan] = ot.[Plan], DtRow = isnull(ot.DtRow, N''), CtRow = isnull(ot.CtRow, N''),
			d.[Date], d.Agent, d.Company, d.RespCenter, d.CostItem, d.WhFrom, d.WhTo, d.CashAccFrom, d.CashAccTo,
			d.[Contract], d.CashFlowItem
		from doc.Documents d
			inner join doc.OpTrans ot on d.TenantId = ot.TenantId and ot.RowKind = N''
			left join cat.CashAccounts accdt on d.TenantId = accdt.TenantId and d.CashAccTo = accdt.Id
			left join cat.CashAccounts accct on d.TenantId = accct.TenantId and d.CashAccFrom = accct.Id
			left join cat.ItemRoleAccounts irdocdt on irdocdt.TenantId = d.TenantId and irdocdt.[Role] = d.ItemRole and irdocdt.AccKind = ot.DtAccKind
			left join cat.ItemRoleAccounts irdocct on irdocct.TenantId = d.TenantId and irdocct.[Role] = d.ItemRole and irdocct.AccKind = ot.CtAccKind
			left join cat.ItemRoleAccounts iraccdt on iraccdt.TenantId = d.TenantId and iraccdt.[Role] = accdt.ItemRole and iraccdt.AccKind = ot.DtAccKind
			left join cat.ItemRoleAccounts iraccct on iraccct.TenantId = d.TenantId and iraccct.[Role] = accct.ItemRole and iraccct.AccKind = ot.CtAccKind
		where d.TenantId = @TenantId and d.Id = @Id and ot.Operation = @Operation
	)
	insert into @trans
	select TrNo, DtCt = 1, Acc = Dt, CorrAcc = Ct, [Plan], RowMode = DtRow, Wh = WhTo, CashAcc = CashAccTo,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, [Sum]
		from TR
	union all 
	select TrNo, DtCt = -1, Acc = Ct, CorrAcc = Dt, [Plan], RowMode = CtRow, Wh = WhFrom, CashAcc = CashAccFrom,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, [Sum]
		from TR;

	insert into jrn.Journal(TenantId, Document, TrNo, [Date], DtCt, [Plan], Account, CorrAccount, [Sum],
		Company, Agent, Warehouse, CashAccount, [Contract], CashFlowItem, CostItem, RespCenter)
	select TenantId = @TenantId, Document = @Id, TrNo,
		[Date], DtCt, [Plan], Acc, CorrAcc, [Sum] = sum([Sum]),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter
	from @trans
	group by TrNo, [Date], DtCt, [Plan], Acc, CorrAcc, 
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter

	if exists(select * from @trans where CashAcc is not null)
	begin
		insert into jrn.CashJournal(TenantId, Document, [Date], InOut, [Sum], Company, Agent, [Contract], CashAccount, CashFlowItem, RespCenter)
		select TenantId = @TenantId, Document = @Id, [Date], InOut = DtCt, [Sum] = sum([Sum]), Company, Agent, [Contract], CashAcc, CashFlowItem, RespCenter
		from @trans
		where CashAcc is not null
		group by [Date], DtCt, Company, Agent, CashAcc, [Contract], CashFlowItem, RespCenter;
	end
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
	delete from jrn.CashJournal where TenantId = @TenantId and Document = @Id;

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

	select @operation = d.Operation, @done = d.Done, @wsp = de.WriteSupplierPrices
	from doc.Documents d
		left join doc.DocumentExtra de on d.TenantId = de.TenantId and d.Id = de.Id
	where d.TenantId = @TenantId and d.Id=@Id;

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

	begin tran;
		exec doc.[Document.Apply.CheckRems] @TenantId= @TenantId, @Id=@Id, @CheckRems = @CheckRems;
		/*
		if @stock = 1
			exec doc.[Document.Apply.Stock] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		*/
		if @acc = 1
			exec doc.[Document.Apply.Account] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @wsp = 1
			exec doc.[Apply.WriteSupplierPrices] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;
		update doc.Documents set Done = 1, DateApplied = getdate() 
			where TenantId = @TenantId and Id = @Id;
	commit tran;
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

	declare @operation bigint, @parent bigint;
	select @parent = Parent, @operation = Operation from doc.OperationLinks where TenantId = @TenantId and Id=@LinkId

	insert into doc.Documents (TenantId, [Date], Operation, Parent, Base, OpLink, Company, Agent, [Contract], [RespCenter], 
		PriceKind, WhFrom, WhTo, Currency, UserCreated, Temp, [Sum])
	output inserted.Id, inserted.Operation into @rtable(id, op)
	select @TenantId, cast(getdate() as date), @operation, @Document, isnull(Base, @Document), @LinkId, Company, Agent, [Contract], [RespCenter], 
		PriceKind, WhFrom, WhTo, Currency, @UserId, 1, [Sum]
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
	declare @elems a2sys.[Id.TableType];
	insert into @elems (Id) values (@Item);

	select [Result!TRem!Object] = null, r.Item, r.Rem, r.[Role]
	from doc.fn_getItemsRems(@CheckRems, @TenantId, @elems, @Date, @Wh) r
	where r.[Role] = @Role;
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

	exec doc.[Document.MainMaps] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

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
		select Id = -@Group, 2, [Name] = N'@[WithoutGroup]', 0, Icon=N'ban'
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
	select [!TPriceItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
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
	group by i.Id, i.Unit, i.[Name], i.Article, i.Memo, i.[Role]
	order by i.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Prices!TPriceItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
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

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	select IsRem = case when j.[Date] < @From then 1 else 0 end, 
		[Agent] = j.[Agent], Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when j.[Date] < @From then _SumDt else 0 end,
		CtStart = case when j.[Date] < @From then _SumCt else 0 end,
		DtSum = case when j.[Date] >= @From then _SumDt else 0 end,
		CtSum = case when j.[Date] >= @From then _SumCt else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
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

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @start money;
	select @start = sum(j.[Sum] * j.DtCt)
	from jrn.Journal j where TenantId = @TenantId and Company = @Company and Account = @acc and [Date] < @From;
	set @start = isnull(@start, 0);
	
	select [Date] = j.[Date], Id=cast([Date] as int), Acc = j.Account, CorrAcc = j.CorrAccount,
		DtCt = j.DtCt, DtSum = j._SumDt, CtSum = j._SumCt
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
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
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
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

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	select [Agent] = j.[Agent], [Contract] = isnull(j.[Contract], 0), Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when DtCt =  1 and j.[Date] < @From then [Sum] else 0 end,
		CtStart = case when DtCt = -1 and j.[Date] < @From then [Sum] else 0 end,
		DtSum = case when DtCt = 1 and j.[Date] >= @From then [Sum] else 0 end,
		CtSum = case when DtCt = -1 and j.[Date] >= @From then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
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

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	select [RespCenter] = j.[RespCenter], [CostItem] = isnull(j.[CostItem], 0), Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when DtCt =  1 and j.[Date] < @From then [Sum] else 0 end,
		CtStart = case when DtCt = -1 and j.[Date] < @From then [Sum] else 0 end,
		DtSum = case when DtCt = 1 and j.[Date] >= @From then [Sum] else 0 end,
		CtSum = case when DtCt = -1 and j.[Date] >= @From then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
		and [Date] < @end;

	with T as (
		select [RespCenter], [CostItem],
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
	select [!TCross!CrossArray] = null, [Wh!!Key] = t.Warehouse, Rem = sum(t.Qty),
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

	insert into cat.Items(TenantId, Id, [Name], [Role]) 
	values
		(@TenantId, 20, N'Товар №1', 50),
		(@TenantId, 21, N'Послуга №1', 51);

	insert into doc.Operations (TenantId, Id, [Uid], [Name], [Form]) values
		(@TenantId, 100, N'137A9E57-D0A6-438E-B9A0-8B84272D5EB3', N'Придбання товарів/послуг',		N'waybillin'),
		(@TenantId, 101, N'E3CB0D62-24AB-4FE3-BD68-DD2453F6B032', N'Оплата постачальнику (банк)',	N'payout'),
		(@TenantId, 102, N'80C9C85D-458E-445B-B35B-8177B40A5D41', N'Оплата постачальнику (готівка)',	N'cashout'),
		(@TenantId, 103, N'D8DDB942-26AB-4402-9FD7-42E62BBCB57D', N'Продаж товарів/послуг',			N'waybillout'),
		(@TenantId, 104, N'C2C94B13-926C-41E5-9446-647B6C23B83E', N'Оплата від покупця (банк)',		N'payin'),
		(@TenantId, 105, N'B31EB587-D242-4A96-8255-B824B1551963', N'Оплата від покупця (готівка)',	N'cashin');

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
		insert into cat.Companies(TenantId, Id, [Name]) values (@TenantId, 10, N'Моє підприємство');

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
		[CostItems!TCostItem!Array] = null;

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

	-- OPERATIONS
	select [!TOperation!Array] = null, [Id!!Id] = o.[Uid],
		[Name], [Memo], [Form], [Transactions!TOpTrans!Array] = null,
		[PrintForms!TOpPrintForm!Array] = null, [Links!TOpLink!Array] = null,
		[MenuLinks!TOpMenuLink!Array] = null,
		[!TApp.Operations!ParentId] = 1
	from doc.Operations o
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
drop type if exists app.[Application.OpPrintForms.TableType];
drop type if exists app.[Application.OpLink.TableType];
drop type if exists app.[Application.OpMenuLink.TableType];
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
	[Form] nvarchar(16)
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
)
go
------------------------------------------------
create type app.[Application.OpMenuLink.TableType] as table
(
	[ParentId] uniqueidentifier,
	Menu nvarchar(32)
)
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
	declare @OpPrintForms app.[Application.OpPrintForms.TableType];
	declare @OpLinks app.[Application.OpLink.TableType];
	declare @OpMenuLinks app.[Application.OpMenuLink.TableType];

	select [AccKinds!Application.AccKinds!Metadata] = null, * from @AccKinds;
	select [Accounts!Application.Accounts!Metadata] = null, * from @Accounts;
	select [CostItems!Application.CostItems!Metadata] = null, * from @CostItems;
	select [ItemRoles!Application.ItemRoles!Metadata] = null, * from @ItemRoles;
	select [ItemRoleAcc!Application.ItemRoles.Accounts!Metadata] = null, * from @ItemRoleAcc;
	select [Operations!Application.Operations!Metadata] = null, * from @Operations;
	select [OpTrans!Application.Operations.Transactions!Metadata] = null, * from @OpTrans;
	select [OpPrintForms!Application.Operations.PrintForms!Metadata] = null, * from @OpPrintForms;
	select [OpLinks!Application.Operations.Links!Metadata] = null, * from @OpLinks;
	select [OpMenuLinks!Application.Operations.MenuLinks!Metadata] = null, * from @OpMenuLinks;
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
@OpPrintForms app.[Application.OpPrintForms.TableType] readonly,
@OpLinks app.[Application.OpLink.TableType] readonly,
@OpMenuLinks app.[Application.OpMenuLink.TableType] readonly
as
begin
	set nocount on
	set transaction isolation level read committed;

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
		t.IsFolder = s.IsFolder,
		t.IsItem = s.IsItem, IsAgent = s.IsAgent, t.IsWarehouse = s.IsWarehouse,
		t.IsBankAccount = s.IsBankAccount, t.IsCash = s.IsCash, t.IsContract = s.IsContract,
		t.IsRespCenter = s.IsRespCenter, t.IsCostItem = s.IsCostItem
	when not matched by target then insert
		(TenantId, [Uid], [Name], Code, [Memo], IsFolder, 
			IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, IsContract, IsRespCenter, IsCostItem) values
		(@TenantId, s.[Uid], s.[Name], s.Code, s.Memo, s.IsFolder,
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
		t.IsFolder = s.[IsFolder]
	when not matched by target then insert
		(TenantId, [Uid], [Name], Memo, IsFolder) values
		(@TenantId, s.Id, s.[Name], s.Memo, s.IsFolder);

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
	
	-- operations
	declare @operationstable table(id bigint, [uid] uniqueidentifier);
	merge doc.Operations as t
	using @Operations as s
	on t.TenantId = @TenantId and t.[Uid] = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Form] = s.[Form]
	when not matched by target then insert
		(TenantId, [Uid], [Name], Memo, [Form]) values
		(@TenantId, s.Id, s.[Name], s.Memo, s.[Form])
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
		(N'acc.date',      N'by.account',  1, N'/reports/account/rto_accdate', N'Обороти рахунку (дата)'),
		(N'acc.agent',     N'by.account',  2, N'/reports/account/rto_accagent', N'Обороти рахунку (контрагент)'),
		(N'acc.agentcntr', N'by.account',  3, N'/reports/account/rto_accagentcontract', N'Обороти рахунку (контрагент+договір)'),
		(N'acc.respcost',  N'by.account',  4, N'/reports/account/rto_respcost', N'Обороти рахунку (центр відповідальності+стаття витрат)'),
		(N'acc.item',      N'by.account',  5, N'/reports/stock/rto_items', N'Оборотно сальдова відомість (об''єкт обліку)'),
		(N'plan.turnover', N'by.plan', 1, N'/reports/plan/turnover',  N'Оборотно сальдова відомість'),
		(N'plan.money',    N'by.plan', 2, N'/reports/plan/cashflow',  N'Відомість по грошових коштах'),
		(N'plan.rems',     N'by.plan', 2, N'/reports/plan/itemrems',  N'Залишики на складах');

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
	declare @df table(id nvarchar(16), [order] int, inout smallint, [url] nvarchar(255), category nvarchar(255), [name] nvarchar(255));
	insert into @df (id, inout, [order], category, [url], [name]) values
		-- Sales
		(N'invoice',    null, 1, N'@[Sales]', N'/document/sales', N'Замовлення клієнта'),
		(N'complcert',  null, 2, N'@[Sales]', N'/document/sales', N'Акт виконаних робіт'),
		(N'waybillout', null, 3, N'@[Sales]', N'/document/sales', N'Продаж товарів/послуг'),
		-- 
		(N'waybillin',  null, 4, N'@[Purchases]', N'/document/purchase', N'Покупка товарів/послуг'),
		--
		(N'movebill',   null, 5, N'@[KindStock]', N'/document/invent', N'Внутрішнє переміщення'),
		(N'inventbill', null, 6, N'@[KindStock]', N'/document/invent', N'Інвентарізація'),
		(N'writeoff',   null, 7, N'@[KindStock]', N'/document/invent', N'Акт списання'),
		(N'writeon',    null, 8, N'@[KindStock]', N'/document/invent', N'Акт оприбуткування'),
		--
		(N'payout',    -1,  10, N'@[Money]', N'/document/money', N'Витрата безготівкових коштів'),
		(N'cashout',   -1,  11, N'@[Money]', N'/document/money', N'Витрата готівки'),
		(N'payin',      1,  12, N'@[Money]', N'/document/money', N'Надходження безготівкових коштів'),
		(N'cashin',     1,  13, N'@[Money]', N'/document/money', N'Надходження готівки'),
		(N'cashmove', null, 14, N'@[Money]', N'/document/money', N'Прерахування коштів'),
		(N'cashoff',  -1,   15, N'@[Money]', N'/document/money', N'Списання коштів'),
		-- 
		(N'manufact',  null, 20, N'@[Manufacturing]', N'/manufacturing/document', N'Виробничий акт-звіт');

	merge doc.Forms as t
	using @df as s on t.Id = s.id and t.TenantId = @TenantId
	when matched then update set
		t.[Name] = s.[name],
		t.[Order] = s.[order],
		t.InOut = s.inout,
		t.[Url] = s.[url],
		t.Category = s.category
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], InOut, Category, [Url]) values
		(@TenantId, s.id, s.[order], s.[name], inout, category, [url])
	when not matched by source and t.TenantId = @TenantId then delete;

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

