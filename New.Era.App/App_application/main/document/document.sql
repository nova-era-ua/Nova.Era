/* Document */
------------------------------------------------
-- TODO: Kill me
create or alter procedure doc.[Document.Index]
@TenantId int = 1,
@UserId bigint,
@Group nvarchar(16)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name],
		o.[Memo], o.[Form],
		[Documents!TDocument!LazyArray] = null
	from doc.Operations o
	where o.TenantId = @TenantId
	order by o.Id;

	-- documents declaration
	select [!TDocument!Array] = null, [Id!!Id] = 0, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation
	from doc.Documents d 
	where d.TenantId = @TenantId and 0 <> 0;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Documents]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation
	from doc.Documents d 
	where d.TenantId = @TenantId and Operation = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.[Form]
	from doc.Operations o
	where o.Id = @Id;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Memo]
	from doc.Documents d
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and o.Menu = @Menu
	order by d.Date;

	-- TODO: order by
	select [Forms!TForm!Array] = null, [Id!!Id] = f.Id, [Name!!Name] = f.[Name]
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
	where o.TenantId = @TenantId and o.Menu = @Menu
	group by f.Id, f.[Name]
	order by f.Id desc;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Form nvarchar(16) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Form
	from doc.Operations o 
		left join doc.Documents d on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.Id = @Id;

	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Documents d on d.TenantId = a.TenantId and d.Agent = a.Id
	where d.Id = @Id and d.TenantId = @Id;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join doc.Documents d on d.TenantId = c.TenantId and d.Company = c.Id
	where d.Id = @Id and d.TenantId = @Id;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Form]
	from doc.Operations where Form = @Form
	order by Id;
end
go
------------------------------------------------
drop procedure if exists doc.[Document.Stock.Metadata];
drop procedure if exists doc.[Document.Stock.Update];
drop type if exists cat.[Document.Stock.TableType];
go
------------------------------------------------
create type cat.[Document.Stock.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Sum] money,
	Operation bigint,
	Agent bigint,
	Memo nvarchar(255)
)
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Document cat.[Document.Stock.TableType];
	select [Document!Document!Metadata] = null, * from @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Update]
@TenantId int = 1,
@UserId bigint,
@Document cat.[Document.Stock.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge doc.Documents as t
	using @Document as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Date] = s.[Date],
		t.[Sum] = s.[Sum],
		t.Agent = s.Agent,
		t.Memo = s.Memo
	when not matched by target then insert
		(TenantId, Operation, [Date], [Sum], Agent, Memo) values
		(@TenantId, s.Operation, s.[Date], s.[Sum], s.Agent, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	exec doc.[Document.Stock.Load] @TenantId = @TenantId, 
	@UserId = @UserId, @Id = @id;
end
go
