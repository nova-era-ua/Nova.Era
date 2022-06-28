/* Person */
-------------------------------------------------
create or alter procedure cat.[Person.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Persons!TPerson!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo]
	from cat.Agents a
	where TenantId = @TenantId and [Person] = 1
end
go
-------------------------------------------------
create or alter procedure cat.[Person.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Person!TPerson!Object] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo]
	from cat.Agents a
	where TenantId = @TenantId and Id = @Id and [Person] = 1;
end
go
-------------------------------------------------
drop procedure if exists cat.[Person.Metadata];
drop procedure if exists cat.[Person.Update];
drop type if exists cat.[Person.TableType];
go
-------------------------------------------------
create type cat.[Person.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Person.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Person cat.[Person.TableType];
	select [Person!Person!Metadata] = null, * from @Person;
end
go
------------------------------------------------
create or alter procedure cat.[Person.Update]
@TenantId int = 1,
@UserId bigint,
@Person cat.[Person.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Agents as t
	using @Person as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[FullName] = s.[FullName],
		t.[Person] = 1
	when not matched by target then insert
		(TenantId, [Name], FullName, Memo, [Person]) values
		(@TenantId, s.[Name], s.FullName, s.Memo, 1)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Person.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
