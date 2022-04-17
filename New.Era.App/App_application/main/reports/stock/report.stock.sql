-- reports stock
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Item.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null,
@Warehouse bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company), @Warehouse = isnull(@Warehouse, Warehouse)
	from usr.Defaults where TenantId = @TenantId and UserId = @UserId;

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	select Item,
		StartQty = sum(case when [Date] < @From then Qty * DtCt else 0 end),
		InQty = sum(case when [Date] >= @From and DtCt = 1 then Qty else 0 end),
		OutQty = sum(case when [Date] >= @From and DtCt = -1 then Qty else 0 end),
		StartSum = sum(case when [Date] < @From then [Sum] * DtCt else 0 end),
		InSum = sum(case when [Date] >= @From and DtCt = 1 then [Sum] else 0 end),
		OutSum = sum(case when [Date] >= @From and DtCt = -1 then [Sum] else 0 end),
		EndQty = cast(0 as float),
		EndSum  = cast(0 as money),
		ItemGroup = grouping(Item)
	into #tmp
	from jrn.Journal where TenantId = @TenantId and Account = @acc and Company = @Company
		and Warehouse = @Warehouse
		and [Date] < @end
	group by rollup(Item);

	update #tmp set EndQty = StartQty + InQty - OutQty, EndSum = StartSum + InSum - OutSum;

	-- turnover

	select [RepData!TRepData!Group] = null, 
		[Item!!GroupMarker] = ItemGroup,
		[Id!!Id] = t.Item,
		[Item!TItem!RefId] = t.Item,
		StartQty, StartSum, InQty, InSum, OutQty, OutSum, EndQty, EndSum,
		[Items!TRepData!Items] = null
	from #tmp t
	order by ItemGroup desc;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TItem!Map] = null, [Id!!Id] = Id, [Name!!Name] = i.[Name], i.Article
	from #tmp t inner join cat.Items i on i.TenantId = @TenantId and t.Item = i.Id


	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!RepData.Warehouse.Id!Filter] = @Warehouse, [!RepData.Warehouse.Name!Filter] = cat.fn_GetWarehouseName(@TenantId, @Warehouse)
end
go
