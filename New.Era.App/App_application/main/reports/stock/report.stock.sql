-- reports stock
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Item.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @From = isnull(@From, getdate());
	set @To = isnull(@To, getdate());

	-- turnover
	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	select [Data!TData!Array] = null, [Id!!Id] = j.Id, [ItemName] = i.[Name]
	from jrn.Journal j left join cat.Items i on j.TenantId = i.TenantId and j.Item = i.Id
		where j.TenantId = @TenantId;


	select [Report!TReport!Object] = null, [Name!!Name] = [Name]
	from rep.Reports where TenantId = @TenantId and Id = @Id;
	select [Data!TData!Array] = null

	select [!$System!] = null,
		[!Data.Period.From!TPeriod!Filter] = @From,
		[!Data.Period.To!TPeriod!Filter] = @To;
end
go
