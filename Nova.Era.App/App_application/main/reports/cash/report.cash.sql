-- reports cash
------------------------------------------------
create or alter procedure rep.[Report.Cash.Turnover.Date.Document.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@Company bigint = -1,
@CashAccount bigint = -1,
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	declare @comp bigint = nullif(@Company, -1);
	declare @cashacc bigint = nullif(@CashAccount, -1);

	
	declare @start money;
	select @start = sum(j.[Sum] * j.InOut)
	from jrn.CashJournal j where TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and (@cashacc is null or j.CashAccount = @cashacc)
		and [Date] < @From;
	set @start = isnull(@start, 0);
	
	select [Date], Document, SumIn = sum(_SumIn), SumOut = sum(_SumOut),
		GrpDate = grouping([Date]), GrpDocument = grouping(Document)
	into #temp
	from jrn.CashJournal j
	where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and (@cashacc is null or j.CashAccount = @cashacc)
		and j.[Date] >= @From and j.[Date] < @end
	group by rollup(j.[Date], j.Document);

	if @@rowcount = 0
		select [RepData!TRepData!Group] = null, [Id!!Id] = 0, [Date] = null, SumStart = @start,
			SumIn = null, SumOut = null, SumEnd = @start, [Agent!TAgent!RefId] = null,
			[Date!!GroupMarker] = 1,
			[Document!!GroupMarker] = 1,
			[Items!TRepData!Items] = null;
	else 
	begin
		with T ([Date], Document, SumStart, SumIn, SumOut, SumEnd, GrpDate, GrpDocument)
		as
			(
				select [Date], Document,
					@start + coalesce(sum(SumIn - SumOut) over (
						partition by GrpDate, GrpDocument order by [Date] rows between unbounded preceding and 1 preceding
					), 0),
					SumIn, SumOut,
					@start + sum(SumIn - SumOut) over (
						partition by GrpDate, GrpDocument  order by [Date] rows between unbounded preceding and current row),
					GrpDate, GrpDocument
				from #temp
			)
		select [RepData!TRepData!Group] = null, [Id!!Id] = T.Document, T.[Date], T.Document,
			[No] = coalesce(d.SNo, cast(d.[No] as nvarchar(50))), [Agent!TAgent!RefId] = d.Agent,
			o.DocumentUrl, OperationName = o.[Name],
			SumStart, SumIn, SumOut, SumEnd, 
			[Date!!GroupMarker] = GrpDate, [Document!!GroupMarker] = GrpDocument,
			[Items!TRepData!Items] = null
		from T
			left join doc.Documents d on d.TenantId = @TenantId and d.Id = T.Document 
			left join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		order by GrpDate desc, GrpDocument desc, T.[Date], T.Document;

		with T as (select d.Agent from #temp t inner join doc.Documents d on d.TenantId = @TenantId and t.Document = d.Id group by Agent)
		select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
		from cat.Agents a inner join T on a.TenantId = @TenantId and a.Id = T.Agent;
    end
	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;


	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @comp, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!RepData.CashAccount.Id!Filter] = @cashacc, [!RepData.CashAccount.Name!Filter] = cat.fn_GetCashAccountName(@TenantId, @CashAccount)
end
go
