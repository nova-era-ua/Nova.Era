/* Operation */
-------------------------------------------------
create or alter procedure doc.[Operation.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Menu!TMenu!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo, Category,
		[Children!TOperation!LazyArray] = null
	from doc.FormsMenu
	where TenantId = @TenantId
	order by [Order], Id;

	-- children declaration. same as Children proc
	select [!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[Journals!TOpJournal!Array] = null
	from doc.Operations where 1 <> 1;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Children]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Children!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo
	from doc.Operations o 
	where TenantId = @TenantId and Menu = @Id
	order by Id;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null,
@Parent nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Operation!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Menu], 
		[Form.Id!TForm!Id] = o.Form, [Form.RowKinds!TForm!] = f.RowKinds,
		[Journals!TOpJournal!Array] = null,
		[JournalStore!TOpJournalStore!Array] = null
	from doc.Operations o
		inner join doc.Forms f on o.TenantId = f.TenantId and o.Form = f.Id
	where o.TenantId = @TenantId and o.Id=@Id;

	select [!TOpJournal!Array]  =null, [Id!!Id] = Id,
		ApplyIf, ApplyMode, Direction,
		[!TOperation.Journals!ParentId] = oj.Operation
	from doc.OpJournal oj where oj.TenantId = @TenantId and oj.Operation = @Id;

	select [!TOpJournalStore!Array] = null, [Id!!Id] = Id, RowKind, IsIn, IsOut,
		[!TOperation.JournalStore!ParentId] = ojs.Operation
	from doc.OpJournalStore ojs 
	where ojs.TenantId = @TenantId and ojs.Operation = @Id;

	select [Forms!TForm!Array] = null, [Id!!Id] = df.Id, [Name!!Name] = df.[Name], RowKinds
	from doc.Forms df
	where df.TenantId = @TenantId
	order by df.Id;

	select [Params!TParam!Object] = null, [ParentMenu] = @Parent;
end
go
-------------------------------------------------
drop procedure if exists doc.[Operation.Metadata];
drop procedure if exists doc.[Operation.Update];
drop type if exists doc.[Operation.TableType];
drop type if exists doc.[OpJournal.TableType];
drop type if exists doc.[OpJournalStore.TableType];
go
-------------------------------------------------
create type doc.[Operation.TableType]
as table(
	Id bigint null,
	[Menu] nvarchar(32),
	[Form] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
-------------------------------------------------
create type doc.[OpJournal.TableType]
as table(
	Id nvarchar(16),
	Operation bigint,
	ApplyIf nvarchar(16),
	ApplyMode nchar(1),
	Direction nchar(1)
)
go
-------------------------------------------------
create type doc.[OpJournalStore.TableType]
as table(
	Id bigint,
	RowKind nchar(4),
	IsIn bit,
	IsOut bit
)
go
------------------------------------------------
create or alter procedure doc.[Operation.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Operation doc.[Operation.TableType];
	declare @Journals doc.[OpJournal.TableType];
	declare @JournalStore doc.[OpJournalStore.TableType];
	select [Operation!Operation!Metadata] = null, * from @Operation;
	select [Journals!Operation.Journals!Metadata] = null, * from @Journals;
	select [JournalStore!Operation.JournalStore!Metadata] = null, * from @JournalStore;
end
go
------------------------------------------------
create or alter procedure doc.[Operation.Update]
@TenantId bigint = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Operation doc.[Operation.TableType] readonly,
@Journals doc.[OpJournal.TableType] readonly,
@JournalStore doc.[OpJournalStore.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	
	declare @rtable table(id bigint);
	declare @Id bigint;

	merge doc.Operations as t
	using @Operation as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Form] = s.[Form]
	when not matched by target then insert
		(TenantId, [Menu], [Name], Form, Memo) values
		(@TenantId, s.[Menu], s.[Name], s.Form, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @Id = id from @rtable;

	merge doc.OpJournal as t
	using @Journals as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.Direction = s.Direction
	when not matched by target then insert
		(TenantId, Operation, Id, Direction) values
		(@TenantId, @Id, s.Id, s.Direction)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	merge doc.OpJournalStore as t
	using @JournalStore as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowKind = s.RowKind,
		t.IsIn = s.IsIn,
		t.IsOut = s.IsOut
	when not matched by target then insert
		(TenantId, Operation, RowKind, IsIn, IsOut) values
		(@TenantId, @Id, RowKind, s.IsIn, s.IsOut)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	exec doc.[Operation.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, @UserId = @UserId,
		@Id = @Id;
end
go
