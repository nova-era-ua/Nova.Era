-- reports account
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Account.Date.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company)
	from usr.Defaults where TenantId = @TenantId and UserId = @UserId;

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @rem money;
	select @rem = sum(j.[Sum] * j.DtCt)
	from jrn.Journal j where TenantId = @TenantId and Company = @Company and Account = @acc and [Date] < @From;
	
	with T as (
		select [Date] = cast(Date as date), Id=cast(Date as int),
			DtSum = sum(case when DtCt = 1 then [Sum] else 0 end),
			CtSum = sum(case when DtCt = -1 then [Sum] else 0 end),
			GrpDate = grouping([Date])
		from jrn.Journal j where TenantId = @TenantId and Company = @Company and Account = @acc
			and [Date] >= @From and [Date] < @end
		group by rollup([Date])
	) select Id, [Date],
		[Start] = @rem + coalesce(sum(DtSum - CtSum) over (
			partition by GrpDate order by [Date]
			rows between unbounded preceding and 1 preceding), 0
		),
		DtSum, CtSum,
		[End] = @rem + sum(DtSum - CtSum) over (
			partition by GrpDate order by [Date]
			rows between unbounded preceding and current row
		),
		GrpDate
	from T;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go

exec rep.[Report.Turnover.Account.Date.Load] 1, 99, 1027
