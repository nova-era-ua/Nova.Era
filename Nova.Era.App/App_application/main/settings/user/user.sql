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
	from appsec.Users u where Tenant = @TenantId and Void = 0;
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
		u.Email, 
		[Password] = cast(null as nvarchar(255)), Confirm = cast(null as nvarchar(255))
	from appsec.Users u where 0 <> 0;
end
go
