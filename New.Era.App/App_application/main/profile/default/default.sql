/* Profile.Default */
------------------------------------------------
create or alter procedure usr.[Default.Load]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
end
go
