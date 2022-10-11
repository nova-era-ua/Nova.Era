-- integration
------------------------------------------------
create or alter procedure app.[Integration.Index]
@TenantId int = 1,
@UserId bigint,
@Mobile bit = 0
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Integration!TIntegration!Array] = null, [Id!!Id] = Id,
		[Name], [Memo], Icon, [Url], Category
	from app.Integrations
	order by [Order]
end
go
