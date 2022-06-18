-- reports stock
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Agent.Load]
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

	select Agent,
		StartSum = sum(case when [Date] < @From then [Sum] * DtCt else 0 end),
		InSum = sum(case when [Date] >= @From and DtCt = 1 then [Sum] else 0 end),
		OutSum = sum(case when [Date] >= @From and DtCt = -1 then [Sum] else 0 end),
		EndSum  = cast(0 as money),
		AgentGroup = grouping(Agent)
	into #tmp
	from jrn.Journal where TenantId = @TenantId and Account = @acc and Company = @Company
		and [Date] < @end
	group by rollup(Agent);

	update #tmp set EndSum = isnull(StartSum, 0) + isnull(InSum, 0) - isnull(OutSum, 0);

	-- turnover

	select [RepData!TRepData!Group] = null, 
		[Agent!!GroupMarker] = AgentGroup,
		[Id!!Id] = t.Agent,
		[Agent!TAgent!RefId] = t.Agent,
		StartSum, InSum, OutSum, EndSum,
		[Items!TRepData!Items] = null
	from #tmp t
	order by AgentGroup desc;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from #tmp t inner join cat.Agents a on a.TenantId = @TenantId and t.Agent = a.Id

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
