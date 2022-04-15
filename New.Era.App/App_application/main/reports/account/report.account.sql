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

	declare @start money;
	select @start = sum(j.[Sum] * j.DtCt)
	from jrn.Journal j where TenantId = @TenantId and Company = @Company and Account = @acc and [Date] < @From;
	set @start = isnull(@start, 0);
	
	select [Date] = j.[Date], Id=cast([Date] as int), Acc = j.Account, CorrAcc = j.CorrAccount,
		DtCt = j.DtCt,
		DtSum = case when DtCt = 1 then [Sum] else 0 end,
		CtSum = case when DtCt = -1 then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
		and [Date] >= @From and [Date] < @end;

	with T as (
		select [Date] = cast([Date] as date), Id=cast([Date] as int),
			DtSum = sum(DtSum), CtSum = sum(CtSum),
			GrpDate = grouping([Date])
		from #tmp 
		group by rollup([Date])
	) select [RepData!TRepData!Group] = null, [Id!!Id] = Id, [Date],
		StartSum = @start + coalesce(sum(DtSum - CtSum) over (
			partition by GrpDate order by [Date]
			rows between unbounded preceding and 1 preceding), 0
		),
		DtSum, CtSum,
		EndSum = @start + sum(DtSum - CtSum) over (
			partition by GrpDate order by [Date]
			rows between unbounded preceding and current row
		),
		[Date!!GroupMarker] = GrpDate,
		[DtCross!TCross!CrossArray] = null,
		[CtCross!TCross!CrossArray] = null,
		[Items!TRepData!Items] = null
	from T
	order by GrpDate desc;

	-- dt cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[DtSum]), [!TRepData.DtCross!ParentId] = t.Id
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = 1
	group by a.Code, t.Id;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), [!TRepData.CtCross!ParentId] = t.Id
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1
	group by a.Code, t.Id;

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

-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Account.Agent.Load]
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

	
	select [Agent] = j.[Agent], Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when DtCt =  1 and j.[Date] < @From then [Sum] else 0 end,
		CtStart = case when DtCt = -1 and j.[Date] < @From then [Sum] else 0 end,
		DtSum = case when DtCt = 1 and j.[Date] >= @From then [Sum] else 0 end,
		CtSum = case when DtCt = -1 and j.[Date] >= @From then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
		and [Date] >= @From and [Date] < @end;

	with T as (
		select [Agent],
			DtStart = sum(DtStart), CtStart = sum(CtStart),
			DtSum = sum(DtSum), CtSum = sum(CtSum), 
			DtEnd = sum(DtStart) + sum(DtSum), 
			CtEnd = sum(CtStart) + sum(CtSum),
			GrpAgent = grouping([Agent])
		from #tmp 
		group by rollup([Agent])
	) select [RepData!TRepData!Group] = null, [Id!!Id] = Agent, [Agent!TAgent!RefId] = Agent,
		DtStart, CtStart,
		DtSum, CtSum,
		DtEnd, CtEnd,
		[Agent!!GroupMarker] = GrpAgent,
		[DtCross!TCross!CrossArray] = null,
		[CtCross!TCross!CrossArray] = null,
		[Items!TRepData!Items] = null
	from T
	order by GrpAgent desc;

	-- agents
	with TA as (select Agent from #tmp group by Agent) 
	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA t on a.TenantId = @TenantId and a.Id = t.Agent;

	-- dt cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[DtSum]), [!TRepData.DtCross!ParentId] = t.Agent
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = 1
	group by a.Code, t.Agent;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), [!TRepData.CtCross!ParentId] = t.Agent
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1
	group by a.Code, t.Agent;

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

--exec rep.[Report.Turnover.Account.Date.Load] 1, 99, 1027 --, N'20220301', N'20220331';
go



