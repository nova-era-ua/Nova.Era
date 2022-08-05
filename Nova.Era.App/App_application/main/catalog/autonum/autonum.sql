/* ACCOUNT KIND */
drop procedure if exists doc.[Autonum.Metadata];
drop procedure if exists doc.[Autonum.Update];
drop type if exists doc.[Autonum.TableType];
go
------------------------------------------------
create type doc.[Autonum.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Period] nchar(1),
	Pattern nvarchar(255)
)
go
------------------------------------------------
create or alter procedure doc.[Autonum.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Autonums!TAutonum!Array] = null,
		[Id!!Id] = an.Id, [Name!!Name] = an.[Name], an.Memo, an.Pattern, an.[Period]
	from doc.Autonums an
	where an.TenantId = @TenantId and an.Void = 0
	order by an.Id;
end
go
------------------------------------------------
create or alter procedure doc.[Autonum.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Autonum!TAutonum!Object] = null,
		[Id!!Id] = an.Id, [Name!!Name] = an.[Name], an.Memo, an.[Period], an.Pattern
	from doc.Autonums an
	where an.TenantId = @TenantId and an.Id = @Id;
end
go
---------------------------------------------
create or alter procedure doc.[Autonum.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Autonum doc.[Autonum.TableType];
	select [Autonum!Autonum!Metadata] = null, * from @Autonum;
end
go
---------------------------------------------
create or alter procedure doc.[Autonum.Update]
@TenantId int = 1,
@UserId bigint,
@Autonum doc.[Autonum.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge doc.Autonums as t
	using @Autonum as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.[Period] = s.[Period],
		t.Pattern = s.[Pattern]
	when not matched by target then insert
		(TenantId, [Name], Memo, [Period], Pattern) values
		(@TenantId, [Name], Memo, [Period], Pattern)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec doc.[Autonum.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure doc.[Autonum.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update doc.Autonums set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

