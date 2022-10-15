/* ACCOUNT KIND */
drop procedure if exists doc.[DocState.Metadata];
drop procedure if exists doc.[DocState.Update];
drop type if exists doc.[DocState.TableType];
go
------------------------------------------------
create type doc.[DocState.TableType] as table
(
	Id nvarchar(32),
	[Name] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure doc.[DocState.Index]
@TenantId int = 1,
@UserId bigint,
@Id nvarchar(32) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Forms!TForm!Array] = null,
		[Id!!Id] = f.Id, [Name!!Name] = f.[Name], f.Memo,
		[States!TState!Array] = null
	from doc.Forms f
	where f.TenantId = @TenantId and f.HasState = 1
	order by f.[Order];

	select [!TState!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color,
		[!TForm.States!ParentId] = ds.Form
	from doc.DocStates ds
	where ds.TenantId = @TenantId and ds.Void = 0
	order by ds.[Order]
end
go
------------------------------------------------
create or alter procedure doc.[DocState.Load]
@TenantId int = 1,
@UserId bigint,
@Id nvarchar(32) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Form!TForm!Object] = null, [Id!!Id] = an.Id, [Name!!Name] = an.[Name], an.Memo,
		[States!TState!Array] = null
	from doc.Forms an
	where an.TenantId = @TenantId and an.Id = @Id;

	select [!TState!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color,
		[!TForm.States!ParentId] = ds.Form
	from doc.DocStates ds
	where ds.TenantId = @TenantId and ds.Void = 0 and ds.Form = @Id
	order by ds.[Order]
end
go
---------------------------------------------
create or alter procedure doc.[DocState.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @DocState doc.[DocState.TableType];
	select [DocState!DocState!Metadata] = null, * from @DocState;
end
go
---------------------------------------------
create or alter procedure doc.[DocState.Update]
@TenantId int = 1,
@UserId bigint,
@DocState doc.[DocState.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge doc.DocStates as t
	using @DocState as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name]
	when not matched by target then insert
		(TenantId, [Name]) values
		(@TenantId, [Name])
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec doc.[DocState.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
