-- SETTINGS.USER

------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'appsec' and ROUTINE_NAME=N'User.Metadata')
	drop procedure appsec.[User.Metadata]
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'appsec' and ROUTINE_NAME=N'User.Update')
	drop procedure appsec.[User.Update]
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'appsec' and DOMAIN_NAME=N'User.TableType' and DATA_TYPE=N'table type')
	drop type appsec.[User.TableType];
go
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
------------------------------------------------
create type appsec.[User.TableType]
as table(
	Id bigint null,
	[UserName] nvarchar(255),
	[Email] nvarchar(255),
	[PhoneNumber] nvarchar(255),
	[Locale] nvarchar(255),
	[PersonName] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure appsec.[User.Metadata]
as
begin
	set nocount on;

	declare @User appsec.[User.TableType];
	select [User!User!Metadata]=null, * from @User;
end
go
------------------------------------------------
create procedure appsec.[User.Update]
	@TenantId int = null,
	@UserId bigint,
	@User appsec.[User.TableType] readonly,
	@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output table(op sysname, id bigint);
	merge appsec.ViewUsers as target
	using @User as source
	on (target.Id = source.Id)
	when matched then
		update set 
			target.[Email] = source.Email,
			target.PhoneNumber = source.[PhoneNumber],
			target.Memo = source.Memo,
			target.PersonName = source.PersonName,
			target.[Locale] = isnull(source.[Locale], N'')
	when not matched by target then
		insert ([UserName], Email, PhoneNumber, Memo, PersonName, SecurityStamp, [Locale])
		values ([UserName], Email, [PhoneNumber], Memo, PersonName, N'', isnull([Locale], N''))
	output 
		$action op,
		inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	exec appsec.[User.Load] @TenantId, @UserId, @RetId;
end
go
