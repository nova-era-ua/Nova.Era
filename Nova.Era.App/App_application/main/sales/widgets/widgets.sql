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