-- SETTINGS.USER
------------------------------------------------
create or alter procedure appsec.[User.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [User!TUser!Array] = null, [Id!!Id] = u.Id, u.UserName, u.PersonName, u.LastLoginHost
	from appsec.Users u where Tenant = @TenantId and Void = 0;

end
go
