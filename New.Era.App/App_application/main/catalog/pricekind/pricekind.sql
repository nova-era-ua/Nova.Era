/* PRICEKINDS */
------------------------------------------------
create or alter procedure cat.[PriceKind.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PriceKind!TPriceKind!Array] = null;
end
go
