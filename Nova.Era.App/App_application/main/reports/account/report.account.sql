-- reports account
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

	select IsRem = case when j.[Date] < @From then 1 else 0 end, 
		[Agent] = j.[Agent], Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when j.[Date] < @From then _SumDt else 0 end,
		CtStart = case when j.[Date] < @From then _SumCt else 0 end,
		DtSum = case when j.[Date] >= @From then _SumDt else 0 end,
		CtSum = case when j.[Date] >= @From then _SumCt else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
		and [Date] < @end;

	with T as (
		select [Agent],
			DtStart = rep.fn_FoldSaldo(1, sum(DtStart), sum(CtStart)),
			CtStart = rep.fn_FoldSaldo(-1, sum(DtStart), sum(CtStart)),
			DtSum = sum(DtSum), 
			CtSum = sum(CtSum), 
			DtEnd = rep.fn_FoldSaldo(1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
			CtEnd = rep.fn_FoldSaldo(-1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
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
	where t.DtCt = 1 and t.IsRem = 0
	group by a.Code, t.Agent;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), [!TRepData.CtCross!ParentId] = t.Agent
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1 and t.IsRem = 0
	group by a.Code, t.Agent;

	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
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
create or alter procedure [rep].[Report.Turnover.Account.Date.Load]
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
		DtCt = j.DtCt, DtSum = j._SumDt, CtSum = j._SumCt
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
		and [Date] >= @From and [Date] < @end;

	if @@rowcount = 0
	begin
		select [RepData!TRepData!Group] = null, [Id!!Id] = 0, [Date] = null, StartSum = @start,
			DtSum = null, CtSum = null, EndSum = @start, 
			[Date!!GroupMarker] = 1,
			[DtCross!TCross!CrossArray] = null,
			[CtCross!TCross!CrossArray] = null,
			[Items!TRepData!Items] = null;
	end
	else 
	begin
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
	end

	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
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
create or alter procedure rep.[Report.Turnover.Account.Agent.Contract.Load]
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

	select [Agent] = j.[Agent], [Contract] = isnull(j.[Contract], 0), Acc = j.Account, CorrAcc = j.CorrAccount, j.DtCt,
		DtStart = case when DtCt =  1 and j.[Date] < @From then [Sum] else 0 end,
		CtStart = case when DtCt = -1 and j.[Date] < @From then [Sum] else 0 end,
		DtSum = case when DtCt = 1 and j.[Date] >= @From then [Sum] else 0 end,
		CtSum = case when DtCt = -1 and j.[Date] >= @From then [Sum] else 0 end
	into #tmp
	from jrn.Journal j where j.TenantId = @TenantId and Company = @Company and Account = @acc
		and [Date] < @end;

	with T as (
		select [Agent], [Contract],
			DtStart = rep.fn_FoldSaldo(1, sum(DtStart), sum(CtStart)),
			CtStart = rep.fn_FoldSaldo(-1, sum(DtStart), sum(CtStart)),
			DtSum = sum(DtSum),
			CtSum = sum(CtSum),
			DtEnd =  rep.fn_FoldSaldo(1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
			CtEnd =  rep.fn_FoldSaldo(-1, sum(DtStart) + sum(DtSum), sum(CtStart) + sum(CtSum)),
			GrpAgent = grouping([Agent]),
			GrpContract = grouping([Contract])
		from #tmp 
		group by rollup([Agent], [Contract])
	) select [RepData!TRepData!Group] = null, [Id!!Id] = rep.fn_MakeRepId2(Agent, [Contract]),
		AgentId = Agent, ContractId = [Contract],
		[Agent!TAgent!RefId] = Agent,
		[Contract!TContract!RefId] = isnull([Contract], 0),
		DtStart, CtStart,
		DtSum, CtSum,
		DtEnd, CtEnd,
		[AgentId!!GroupMarker] = GrpAgent,
		[ContractId!!GroupMarker] = GrpContract,
		[DtCross!TCross!CrossArray] = null,
		[CtCross!TCross!CrossArray] = null,
		[Items!TRepData!Items] = null
	from T
	order by GrpAgent desc, GrpContract desc;

	-- agents
	with TA as (select Agent from #tmp group by Agent) 
	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA t on a.TenantId = @TenantId and a.Id = t.Agent;

	-- contracts
	with TA as (select [Contract] from #tmp group by [Contract]) 
	select [!TContract!Map] = null, [Id!!Id] = Id, [Name!!Name] = c.[Name], c.SNo, c.[Date]
	from doc.Contracts c inner join TA t on c.TenantId = @TenantId and c.Id = t.[Contract];

	-- dt cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[DtSum]), 
		[!TRepData.DtCross!ParentId] = rep.fn_MakeRepId2(t.Agent, t.[Contract])
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = 1 and t.DtSum <> 0
	group by a.Code, t.[Contract], t.Agent;

	-- ct cross
	select [!TCross!CrossArray] = null, [Acc!!Key] = a.Code, [Sum] = sum(t.[CtSum]), 
		[!TRepData.CtCross!ParentId] = rep.fn_MakeRepId2(t.Agent, t.[Contract])
	from #tmp t
		inner join acc.Accounts a on a.TenantId = @TenantId and t.CorrAcc = a.Id
	where t.DtCt = -1 and t.CtSum <> 0
	group by a.Code, t.[Contract], t.Agent;

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



