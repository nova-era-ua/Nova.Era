-- reports settle
------------------------------------------------
create or alter procedure rep.[Report.Settle.Turnover.Date.Agent.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@Company bigint = -1,
@Agent bigint = -1,
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	declare @comp bigint = nullif(@Company, -1);
	declare @ag bigint = nullif(@Agent, -1);

	
	declare @start money;
	select @start = sum(j.[Sum] * j.IncDec)
	from jrn.SettleJournal j where TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and (@agent is null or j.Agent = @ag)
		and [Date] < @From;
	set @start = isnull(@start, 0);
	
	select [Date], Agent, SumInc = sum(_SumInc), SumDec = sum(_SumDec),
		GrpDate = grouping([Date]), GrpAgent = grouping(Agent)
	into #temp
	from jrn.SettleJournal j
	where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and (@ag is null or j.Agent = @ag)
		and j.[Date] >= @From and j.[Date] < @end
	group by rollup(j.[Date], j.Agent);

	if @@rowcount = 0
		select [RepData!TRepData!Group] = null, [Id!!Id] = 0, [Date] = null, SumStart = @start,
			SumInc = null, SumDec = null, SumEnd = @start, [Agent!TAgent!RefId] = null,
			[Date!!GroupMarker] = 1,
			[Agent!!GroupMarker] = 1,
			[Items!TRepData!Items] = null;
	else 
	begin
		with T ([Date], Agent, SumStart, SumInc, SumDec, SumEnd, GrpDate, GrpAgent)
		as
			(
				select [Date], Agent,
					@start + coalesce(sum(SumInc - SumDec) over (
						partition by GrpDate, GrpAgent order by [Date] rows between unbounded preceding and 1 preceding
					), 0),
					SumInc, SumDec,
					@start + sum(SumInc - SumDec) over (
						partition by GrpDate, GrpAgent order by [Date] rows between unbounded preceding and current row),
					GrpDate, GrpAgent
				from #temp
			)
		select [RepData!TRepData!Group] = null, [Id!!Id] = T.Agent, T.[Date],
			[Agent!TAgent!RefId] = T.Agent,
			SumStart, SumInc, SumDec, SumEnd, 
			[Date!!GroupMarker] = GrpDate, [Agent!!GroupMarker] = GrpAgent,
			[Items!TRepData!Items] = null
		from T
		order by GrpDate desc, GrpAgent desc, T.[Date], T.Agent;

		with T as (select t.Agent from #temp t group by Agent)
		select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
		from cat.Agents a inner join T on a.TenantId = @TenantId and a.Id = T.Agent;
    end
	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;


	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @comp, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!RepData.Agent.Id!Filter] = @ag, [!RepData.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent)
end
go
