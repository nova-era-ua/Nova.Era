-- integration
------------------------------------------------
create or alter procedure app.[Integration.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Model!TModel!Array] = null, [Id!!Id] = null
end
go

