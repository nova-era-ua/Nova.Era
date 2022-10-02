-- CONTRACT
drop procedure if exists doc.[Contract.Maps];
drop type if exists doc.[Contract.Index.TableType]
go
-------------------------------------------------
create type doc.[Contract.Index.TableType] as table
(
	rowno int identity(1, 1), 
	id bigint, 
	agent bigint, 
	comp bigint, 
	pkind bigint, 
	kind nvarchar(16), 
	rowcnt int
);
go
-------------------------------------------------
create or alter procedure doc.[Contract.Maps]
@TenantId int = 1,
@Elems doc.[Contract.Index.TableType] readonly
as
begin
	-- maps
	with T as (select agent from @Elems group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with T as (select comp from @Elems group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	with T as (select pkind from @Elems group by pkind)
	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk 
		inner join T t on pk.TenantId = @TenantId and pk.Id = pkind;

	with T as (select kind from @Elems group by kind)
	select [!TContractKind!Map] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from doc.ContractKinds ck 
		inner join T t on ck.TenantId = @TenantId and ck.Id = kind;
end
go
-------------------------------------------------
create or alter procedure doc.[Contract.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Agent bigint = null,
@Company bigint = null,
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';

	declare @cnts doc.[Contract.Index.TableType];

	insert into @cnts(id, agent, comp, pkind, kind, rowcnt)
	select c.Id, c.Agent, c.Company, c.PriceKind, c.Kind,
		count(*) over()
	from doc.Contracts c
	where c.TenantId = @TenantId and c.Void = 0
		and (@Agent is null or c.Agent = @Agent)
		and (@Company is null or c.Company = @Company)
		and (@fr is null or c.[Name] like @fr or c.[SNo] like @fr or c.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'date' then c.[Date]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'sno' then c.[SNo]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'date' then c.[Date]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'sno' then c.[SNo]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Contracts!TContract!Array] = null, [Id!!Id] = c.Id, c.[Date], [Name!!Name] = c.[Name], c.[Memo], c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company,
		[PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TContractKind!RefId] = c.Kind,
		[!!RowCount] = t.rowcnt
	from @cnts t inner join 
		doc.Contracts c on c.TenantId = @TenantId and c.Id = t.id
	order by t.rowno;

	-- maps
	exec doc.[Contract.Maps] @TenantId, @cnts;

	select [!$System!] = null, [!Contracts!Offset] = @Offset, [!Contracts!PageSize] = @PageSize, 
		[!Contracts!SortOrder] = @Order, [!Contracts!SortDir] = @Dir,
		[!Contracts.Agent.Id!Filter] = @Agent, [!Contracts.Agent.Name!Filter] = cat.fn_GetAgentName(@TenantId, @Agent),
		[!Contracts.Company.Id!Filter] = @Company, [!Contracts.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
		[!Contracts.Fragment!Filter] = @Fragment;
end
go
-------------------------------------------------
create or alter procedure doc.[Contract.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Contract!TContract!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Date], c.Memo, c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company, [PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TContractKind!RefId] = c.Kind
	from doc.Contracts c
	where c.TenantId = @TenantId and c.Id = @Id;

	-- maps
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Contracts c on c.TenantId = a.TenantId and c.Agent = a.Id
	where c.Id = @Id and c.TenantId = @TenantId;


	select [!TCompany!Map] = null, [Id!!Id] = cmp.Id, [Name!!Name] = cmp.[Name]
	from cat.Companies cmp inner join doc.Contracts c on cmp.TenantId = c.TenantId and c.Company = cmp.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk inner join doc.Contracts c on pk.TenantId = c.TenantId and c.PriceKind = pk.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [ContractKinds!TContractKind!Array] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from doc.ContractKinds ck
	where ck.TenantId = @TenantId order by [Order];

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;

	select [Params!TParam!Object] = null, 
		[Agent.Id!TAgent!Id] = @Agent, [Agent.Name!TAgent!Name] = cat.fn_GetAgentName(@TenantId, @Agent),
		[Company.Id!TCompany!Id] =@Company, [Company.Name!TCompany!Name] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
-------------------------------------------------
drop procedure if exists doc.[Contract.Metadata];
drop procedure if exists doc.[Contract.Update];
drop type if exists doc.[Contract.TableType];
go
-------------------------------------------------
create type doc.[Contract.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	SNo nvarchar(255),
	[Date] date,
	Company bigint,
	Agent bigint,
	PriceKind bigint,
	Kind nvarchar(16)
)
go
------------------------------------------------
create or alter procedure doc.[Contract.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Contract doc.[Contract.TableType];
	select [Contract!Contract!Metadata] = null, * from @Contract;
end
go
------------------------------------------------
create or alter procedure doc.[Contract.Update]
@TenantId int = 1,
@UserId bigint,
@Contract doc.[Contract.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge doc.Contracts as t
	using @Contract as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Date] = s.[Date],
		t.SNo =  s.SNo,
		t.Company = s.Company,
		t.Agent = s.Agent,
		t.PriceKind = s.PriceKind,
		t.Kind = s.Kind
	when not matched by target then insert
		(TenantId, [Name], Memo, [Date], SNo, Company, Agent, PriceKind, Kind) values
		(@TenantId, s.[Name], s.Memo, s.[Date], s.[SNo], s.Company, s.Agent, s.PriceKind, s.Kind)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec doc.[Contract.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

-------------------------------------------------
create or alter procedure doc.[Contract.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update doc.Contracts set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

-------------------------------------------------
create or alter procedure doc.[Contract.Show.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Contract!TContract!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Date], c.Memo, c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company, [PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TContractKind!RefId] = c.Kind,
		[Documents!TDocument!LazyArray] = null
	from doc.Contracts c
	where c.TenantId = @TenantId and c.Id = @Id;

	-- maps
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Contracts c on c.TenantId = a.TenantId and c.Agent = a.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [!TCompany!Map] = null, [Id!!Id] = cmp.Id, [Name!!Name] = cmp.[Name]
	from cat.Companies cmp inner join doc.Contracts c on cmp.TenantId = c.TenantId and c.Company = cmp.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk inner join doc.Contracts c on pk.TenantId = c.TenantId and c.PriceKind = pk.Id
	where c.Id = @Id and c.TenantId = @TenantId;

	select [!TContractKind!Array] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from doc.ContractKinds ck inner join doc.Contracts c on ck.TenantId = c.TenantId and c.Kind = ck.Id
	where ck.TenantId = @TenantId order by [Order];

	-- declarations
	select [Documents!TDocument!Array] = null, [Id!!Id] = Id, [Date], [No], SNo, [Sum], Memo, Done,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company, [Operation!TOperation!RefId] = d.Operation
	from doc.Documents d
	where d.TenantId = @TenantId and 1 <> 1;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form, o.DocumentUrl
	from doc.Operations o 
		where o.TenantId = @TenantId and 0 <> 0;
end
go
-------------------------------------------------
create or alter procedure doc.[Contract.Show.Documents]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'desc',
@Agent bigint = null,
@Company bigint = null,
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
	from doc.Documents d 
	where d.TenantId = @TenantId and d.[Contract] = @Id
		and (d.[Date] >= @From and d.[Date] < @end)
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

	select [Documents!TDocument!Array] = null, [Id!!Id] = Id, [Date], [No], SNo, [Sum], Memo, Done,
		[Agent!TAgent!RefId] = d.Agent, [Company!TCompany!RefId] = d.Company, [Operation!TOperation!RefId] = d.Operation,
		[!!RowCount] = t.rowcnt
	from @docs t inner join doc.Documents d on d.TenantId = @TenantId and d.Id = t.doc;

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

	select [!$System!] = null, [!Documents!Offset] = @Offset, [!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To;
end
go

-------------------------------------------------
create or alter procedure doc.[Contract.Fetch]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	set @Company = nullif(@Company, 0);
	set @Agent = nullif(@Agent, 0);

	declare @cnts doc.[Contract.Index.TableType];

	insert into @cnts(id, agent, comp, pkind, kind)
	select top(100) c.Id, c.Agent, c.Company, c.PriceKind, c.Kind
	from doc.Contracts c
	where c.TenantId = @TenantId and c.Void = 0
		and (@Agent is null or c.Agent = @Agent)
		and (@Company is null or c.Company = @Company)
		and (c.[Name] like @fr or c.[SNo] like @fr or c.Memo like @fr);

	select [Contracts!TContract!Array] = null, [Id!!Id] = c.Id, c.[Date], [Name!!Name] = c.[Name], c.[Memo], c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company,
		[PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TContractKind!RefId] = c.Kind
	from @cnts t inner join 
		doc.Contracts c on c.TenantId = @TenantId and c.Id = t.id;

	-- maps
	exec doc.[Contract.Maps] @TenantId, @cnts;

end
go
