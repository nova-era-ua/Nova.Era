/* Accounting plan */
------------------------------------------------
create or alter procedure acc.[Accounting.Account.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with T(Id, Parent, [Level])
	as (
		select a.Id, Parent, 0 from
			acc.Accounts a where TenantId=@TenantId and a.Parent is null and a.[Plan] is null and Void=0
		union all 
		select a.Id, a.Parent, T.[Level] + 1 
		from acc.Accounts a
			inner join T on T.Id = a.Parent and a.TenantId = @TenantId and a.Void = 0
		where a.TenantId = @TenantId
	)
	select [Accounts!TAccount!Tree] = null, [Id!!Id] = T.Id, a.Code, a.[Name], a.[Plan], a.IsFolder,
		[Items!TAccount!Items] = null, [!TAccount.Items!ParentId] = T.Parent,
		[Documents!TDocument!LazyArray] = null
	from T inner join acc.Accounts a on a.Id = T.Id and a.TenantId = @TenantId
	order by T.[Level], a.Code;

	-- declarations
	select [!TDocument!LazyArray] = null, [Id!!Id] = Id, [Date], [Sum], Memo,
		[Agent!TAgent!RefId] = Agent, [Company!TCompany!RefId] = Company,
		[Operation!TOperation!RefId] = Operation,
		[!!RowCount] = 0
	from doc.Documents where 1 <> 1;

	select [!TAgent!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Agents where 1 <> 1;

	select [!TCompany!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Companies where 1 <> 1;

	select [!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o where 1 <> 1;
end
go
------------------------------------------------
create or alter procedure acc.[Accounting.Account.Documents]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'desc',
@From date = null,
@To date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date;
	set @end = dateadd(day, 1, @To);

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @docs table(doc bigint, agent bigint, company bigint, operation bigint, rowcnt int)
	insert into @docs(doc, agent, company, operation, rowcnt)
	select d.Id, d.Agent, d.Company, d.Operation,
		count(*) over()
	from jrn.Journal j
		inner join doc.Documents d on j.TenantId = d.TenantId and j.Document = d.Id
	where j.TenantId = @TenantId and j.Account = @Id
		and (j.[Date] >= @From and j.[Date] < @end)
	group by d.Id, d.Agent, d.Company, d.[Date], d.[Sum], d.Operation
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'date' then d.[Date]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'sum' then d.[Sum]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'date' then d.[Date]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'sum' then d.[Sum]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Documents!TDocument!Array] = null, [Id!!Id] = Id, [Date], [Sum], d.Memo,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company,
		[Operation!TOperation!RefId] = d.Operation,
		[!!RowCount] = t.rowcnt
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and t.doc = d.Id;

	-- maps
	with TA as(select agent from @docs group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join TA on a.TenantId = @TenantId and a.Id = TA.agent;

	with TC as(select company from @docs group by company)
	select [!TCompany!Map] = null, [Id!!Id] = Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join TC on c.TenantId = @TenantId and c.Id = TC.company;

	with T as (select operation from @docs group by operation)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o 
		inner join T t on o.TenantId = @TenantId and o.Id = operation;

	select [!$System!] = null, 
		[!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To;
		--[!Documents.Operation!Filter] = @Operation
end
go
