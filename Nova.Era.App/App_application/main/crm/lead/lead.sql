-- Lead
drop procedure if exists crm.[Lead.Maps];
drop type if exists crm.[Lead.Index.TableType]
go
-------------------------------------------------
create type crm.[Lead.Index.TableType] as table
(
	rowno int identity(1, 1), 
	id bigint, 
	agent bigint,
	contact bigint,
	currency bigint,
	rowcnt int
);
go
-------------------------------------------------
create or alter procedure crm.[Lead.Maps]
@TenantId int = 1,
@Elems crm.[Lead.Index.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	-- maps
	with T as (select agent from @Elems where agent is not null group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with T as (select contact from @Elems where contact is not null group by contact)
	select [!TContact!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Contacts c 
		inner join T t on c.TenantId = @TenantId and c.Id = contact;

	select [Stages!TStage!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color, Kind
	from crm.LeadStages 
	where TenantId = @TenantId and Void = 0 order by [Order];
end
go
-------------------------------------------------
create or alter procedure crm.[Lead.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'desc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';

	declare @leads crm.[Lead.Index.TableType];

	insert into @leads(id, agent, contact, currency, rowcnt)
	select c.Id, c.Agent, c.Contact, c.Currency,
		count(*) over()
	from crm.Leads c
	where c.TenantId = @TenantId and c.Void = 0
		and (@fr is null or c.[Name] like @fr or c.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'date' then c.[UtcDateCreated]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order 
				when N'date' then c.[UtcDateCreated]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Leads!TLead!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Memo],
		[Agent!TAgent!RefId] = c.Agent, [Contact!TContact!RefId] = c.Contact, [Stage!TStage!RefId] = c.Stage,
		c.Amount, [Currency!TCurrency!RefId] = c.Currency,
		[DateCreated!!Utc] = c.UtcDateCreated,
		[!!RowCount] = t.rowcnt
	from @leads t inner join 
		crm.Leads c on c.TenantId = @TenantId and c.Id = t.id
	order by t.rowno;

	-- maps
	exec crm.[Lead.Maps] @TenantId, @leads;

	select [!$System!] = null, [!Leads!Offset] = @Offset, [!Leads!PageSize] = @PageSize, 
		[!Leads!SortOrder] = @Order, [!Leads!SortDir] = @Dir,
		[!Leads.Fragment!Filter] = @Fragment;
end
go
-------------------------------------------------
create or alter procedure crm.[Lead.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Lead!TLead!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo,
		[Agent!TAgent!RefId] = c.Agent, [Contact!TContact!RefId] = c.Contact, [Stage!TStage!RefId] = c.Stage,
		c.Amount, [Currency!TCurrency!RefId] = c.Currency,
		[DateCreated!!Utc] = c.UtcDateCreated
	from crm.Leads c
	where c.TenantId = @TenantId and c.Id = @Id;

	declare @leads crm.[Lead.Index.TableType];
	insert into @leads(agent, contact, currency) 
	select Agent, Contact, Currency 
	from crm.Leads where TenantId = @TenantId and Id = @Id;

	-- maps
	exec crm.[Lead.Maps] @TenantId, @leads;
end
go
-------------------------------------------------
drop procedure if exists crm.[Lead.Metadata];
drop procedure if exists crm.[Lead.Update];
drop type if exists crm.[Lead.TableType];
go
-------------------------------------------------
create type crm.[Lead.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	Memo nvarchar(255),
	Contact bigint,
	Agent bigint,
	Amount money,
	Currency bigint,
	Stage bigint
)
go
------------------------------------------------
create or alter procedure crm.[Lead.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Lead crm.[Lead.TableType];
	select [Lead!Lead!Metadata] = null, * from @Lead;
end
go
------------------------------------------------
create or alter procedure crm.[Lead.Update]
@TenantId int = 1,
@UserId bigint,
@Lead crm.[Lead.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge crm.Leads as t
	using @Lead as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.Stage = s.Stage,
		t.Contact = s.Contact,
		t.Agent = s.Agent,
		t.Amount = s.Amount,
		t.Currency = s.Currency,
		t.UtcDateModified = getutcdate(),
		t.UserModified = @UserId
	when not matched by target then insert
		(TenantId, [Name], Memo, Stage, Contact, Agent, Amount, Currency, 
			UserCreated, UserModified, UtcDateModified) values
		(@TenantId, s.[Name], s.Memo, s.Stage, s.Contact, s.Agent, s.Amount, s.Currency,
		    @UserId, @UserId, getutcdate())
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec crm.[Lead.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

-------------------------------------------------
create or alter procedure crm.[Lead.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update crm.Leads set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

-------------------------------------------------
create or alter procedure crm.[Lead.Fetch]
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

	declare @cnts crm.[Lead.Index.TableType];

	/*
	insert into @cnts(id, agent, comp, pkind, kind)
	select top(100) c.Id, c.Agent, c.Company, c.PriceKind, c.Kind
	from crm.Leads c
	where c.TenantId = @TenantId and c.Void = 0
		and (@Agent is null or c.Agent = @Agent)
		and (@Company is null or c.Company = @Company)
		and (c.[Name] like @fr or c.[SNo] like @fr or c.Memo like @fr);

	select [Leads!TLead!Array] = null, [Id!!Id] = c.Id, c.[Date], [Name!!Name] = c.[Name], c.[Memo], c.SNo,
		[Agent!TAgent!RefId] = c.Agent, [Company!TCompany!RefId] = c.Company,
		[PriceKind!TPriceKind!RefId] = c.PriceKind,
		[Kind!TLeadKind!RefId] = c.Kind
	from @cnts t inner join 
		crm.Leads c on c.TenantId = @TenantId and c.Id = t.id;
	*/
	-- maps
	exec crm.[Lead.Maps] @TenantId, @cnts;

end
go
