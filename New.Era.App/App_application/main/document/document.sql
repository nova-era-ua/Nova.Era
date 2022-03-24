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
	select [!TDocument!Array] = null, [Id!!Id] = 0, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation
	from doc.Documents d 
	where d.TenantId = @TenantId and 0 <> 0;
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

	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation
	from doc.Documents d 
	where d.TenantId = @TenantId and Operation = @Id;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form.Id!TForm!Id] = df.Id, [Form.Url!TForm!] = df.[Url]
	from doc.Operations o
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where o.Id = @Id;
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

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], d.Memo, d.[Sum],
		[Operation!TOperation!RefId] = d.Operation, [Agent!TAgent!RefId] = d.Agent
	from doc.Documents d
	where d.TenantId = @TenantId and d.Id = @Id

	select [Params!TParam!Object] = null,
		[Operation!TOperation!RefId] = @Operation;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form.Id!TForm!Id] = df.Id, [Form.Url!TForm!] = df.[Url]
	from doc.Operations o 
		left join doc.Documents d on d.TenantId = o.TenantId and d.Operation = o.Id
		left join doc.DocumentForms df on o.TenantId = df.TenantId and o.DocumentForm = df.Id
	where d.Id = @Id or o.Id = @Operation;

	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a inner join doc.Documents d on d.TenantId = a.TenantId and d.Agent = a.Id
	where d.Id = @Id and d.TenantId = @Id;

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
		t.[Sum] = s.[Sum],
		t.Agent = s.Agent,
		t.Memo = s.Memo
	when not matched by target then insert
		(TenantId, Company, Operation, [Date], [Sum], Agent, Memo) values
		(@TenantId, @CompanyId, s.Operation, s.[Date], s.[Sum], s.Agent, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	exec doc.[Document.Stock.Load] @TenantId = @TenantId, @CompanyId=@CompanyId, 
	@UserId = @UserId, @Id = @id;
end
go
