/* Document */

------------------------------------------------
create or alter procedure doc.[Document.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Group nvarchar(16)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name],
		o.[Memo],
		[Form.Id!TForm!Id] = df.Id, [Form.Url!TForm!] = df.[Url],
		[Documents!TDocument!LazyArray] = null
	from doc.Operations o
	left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where o.TenantId = @TenantId and o.[Group] = @Group
	order by o.Id;

	-- documents declaration
	select [!TDocument!Array] = null, [Id!!Id] = 0, [Date],
		[Operation!TOperation!RefId] = d.Operation
	from doc.Documents d 
		left join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where d.TenantId = @TenantId and 0 <> 0;

	select [!TOperation!Map] = null, [Id!!Id] = 0
	from doc.Operations o
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where o.TenantId = @TenantId and 0 <> 0;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Documents]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, [Date],
		[Opearation!TOperation!RefId] = d.Operation
	from doc.Documents d 
	where d.TenantId = @TenantId and Operation = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id
		from doc.Operations o
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null,
@Operation bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date],
		[Operation.Id!TOperation!Id] = d.Operation, [Operation.Name!TOperation!] = o.[Name]
	from doc.Documents d
		left join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Id = @Id

	select [Params!TParam!Object] = null,
		[Operation.Id!TOperation!Id] = o.Id, [Operation.Name!TOperation!] = o.[Name]
	from doc.Operations o where TenantId = @TenantId and o.Id = @Operation;
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
	Operation bigint,
	Agent bigint
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
@CompanyId bigint = 0,
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
		t.Agent = s.Agent
	when not matched by target then insert
		(TenantId, Company, Operation, [Date], Agent) values
		(@TenantId, @CompanyId, s.Operation, s.[Date], s.Agent)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec doc.[Document.Stock.Load] @TenantId = @TenantId, @CompanyId=@CompanyId, 
	@UserId = @UserId, @Id = @id;
end
go
