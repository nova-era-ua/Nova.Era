/* PRICELIST */
------------------------------------------------
create or alter procedure cat.[PriceList.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PriceLists!TPriceList!Array] = null;
end
go
