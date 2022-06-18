/* ACCOUNT KIND */
drop procedure if exists acc.[AccKind.Metadata];
drop procedure if exists acc.[AccKind.Update];
drop type if exists acc.[AccKind.TableType];
go
------------------------------------------------
create type acc.[AccKind.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure acc.[AccKind.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [AccKinds!TAccKind!Array] = null,
		[Id!!Id] = ak.Id, [Name!!Name] = ak.[Name], ak.Memo
	from acc.AccKinds ak
	where ak.TenantId = @TenantId and ak.Void = 0
	order by ak.Id;
end
go
------------------------------------------------
create or alter procedure acc.[AccKind.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [AccKind!TAccKind!Object] = null,
		[Id!!Id] = ak.Id, [Name!!Name] = ak.[Name], ak.Memo
	from acc.AccKinds ak
	where ak.TenantId = @TenantId and ak.Id = @Id;
end
go
---------------------------------------------
create or alter procedure acc.[AccKind.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @AccKind acc.[AccKind.TableType];
	select [AccKind!AccKind!Metadata] = null, * from @AccKind;
end
go
---------------------------------------------
create or alter procedure acc.[AccKind.Update]
@TenantId int = 1,
@UserId bigint,
@AccKind acc.[AccKind.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge acc.AccKinds as t
	using @AccKind as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec acc.[AccKind.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure acc.[AccKind.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update acc.AccKinds set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

