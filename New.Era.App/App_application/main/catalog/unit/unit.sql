/* UNIT */
drop procedure if exists cat.[Unit.Metadata];
drop procedure if exists cat.[Unit.Update];
drop type if exists cat.[Unit.TableType];
go
create type cat.[Unit.TableType] as table
(
	Id bigint,
	[Short] nvarchar(8),
	[CodeUA] nchar(4),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Unit.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Units!TUnit!Array] = null,
		[Id!!Id] = u.Id, [Name!!Name] = u.[Name], u.Memo, u.[Short], u.CodeUA
	from cat.Units u
	where TenantId = @TenantId
	order by u.Id;
end
go
------------------------------------------------
create or alter procedure cat.[Unit.Catalog.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- TenantId = 0 => Catalog
	exec cat.[Unit.Index] @TenantId = 0, @UserId = @UserId, @Id = @Id;
end
go
------------------------------------------------
create or alter procedure cat.[Unit.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Unit!TUnit!Object] = null,
		[Id!!Id] = u.Id, [Name!!Name] = u.[Name], u.Memo, u.[Short], u.CodeUA
	from cat.Units u
	where u.TenantId = @TenantId and u.Id = @Id;
end
go
---------------------------------------------
create or alter procedure cat.[Unit.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Unit cat.[Unit.TableType];
	select [Unit!Unit!Metadata] = null, * from @Unit;
end
go
---------------------------------------------
create or alter procedure cat.[Unit.Update]
@TenantId int = 1,
@UserId bigint,
@Unit cat.[Unit.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Units as t
	using @Unit as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[Short] = s.[Short],
		t.[CodeUA] = s.[CodeUA]
	when not matched by target then insert
		(TenantId, [Name], Memo, Short, CodeUA) values
		(@TenantId, [Name], Memo, Short, CodeUA)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Unit.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Unit.AddFromCatalog]
@TenantId int = 1,
@UserId bigint,
@Ids nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	merge cat.Units as t
	using (
		select u.Id, u.Short, u.CodeUA, u.[Name] 
		from cat.Units u
			inner join string_split(@Ids, N',') t on u.TenantId = 0 and u.Id = t.[value]) as s
	on t.TenantId = @TenantId and t.CodeUA = s.CodeUA
	when matched then update set 
		Short = s.Short,
		[Name] = s.[Name],
		Void = 0
	when not matched by target then insert
		(TenantId, Short, CodeUA, [Name]) values
		(@TenantId, s.Short, s.CodeUA, s.[Name]);
end
go
---------------------------------------------
create or alter procedure cat.[Unit.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Units set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

