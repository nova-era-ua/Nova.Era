/* ACCOUNT KIND */
drop procedure if exists doc.[DocState.Item.Metadata];
drop procedure if exists doc.[DocState.Item.Update];
drop procedure if exists doc.[DocState.Update]; -- temp
drop type if exists doc.[DocState.TableType];
go
------------------------------------------------
create type doc.[DocState.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Order] int,
	[Kind] nchar(1), -- (I)nit, (P)rocess, [S]uccess, C(ancel)
	[Memo] nvarchar(255),
	[Form] nvarchar(16)
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

	select [Form!TForm!MainObject] = null, [Id!!Id] = an.Id, [Name!!Name] = an.[Name], an.Memo,
		[States!TState!Array] = null
	from doc.Forms an
	where an.TenantId = @TenantId and an.Id = @Id;

	select [!TState!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color,
		[Order], [Kind], Memo,
		[!TForm.States!ParentId] = ds.Form
	from doc.DocStates ds
	where ds.TenantId = @TenantId and ds.Void = 0 and ds.Form = @Id
	order by ds.[Order];
end
go
------------------------------------------------
create or alter procedure doc.[DocState.Item.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Form nvarchar(16) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [State!TState!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color,
		[Order], [Kind], Memo, Form
	from doc.DocStates ds
	where ds.TenantId = @TenantId and ds.Void = 0 and ds.Id = @Id;

	select [Params!TParam!Object] = null, [NextOrdinal] = isnull(max([Order]), 0) + 1, Form = @Form
	from doc.DocStates
	where TenantId = @TenantId and Form = @Form;
end
go
---------------------------------------------
create or alter procedure doc.[DocState.Item.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @DocState doc.[DocState.TableType];
	select [State!State!Metadata] = null, * from @DocState;
end
go
---------------------------------------------
create or alter procedure doc.[DocState.Item.Update]
@TenantId int = 1,
@UserId bigint,
@State doc.[DocState.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge doc.DocStates as t
	using @State as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name],
		t.Memo = s.Memo,
		t.Color = s.Color,
		t.[Order] = s.[Order],
		t.Kind = s.Kind
	when not matched by target then insert
		(TenantId, Form, [Name], Memo, Color, [Order], Kind) values
		(@TenantId, [Form], [Name], Memo, Color, [Order], Kind)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec doc.[DocState.Item.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure doc.[DocState.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if @Id < 100
		throw 60000, N'UI:@[Error.Delete.System]', 0;
	if exists(select * from doc.Documents where [State] = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update doc.DocStates set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

