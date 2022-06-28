-- Warehouse
------------------------------------------------
create or alter procedure cat.[Warehouse.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Warehouses!TWarehouse!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[RespPerson!TPerson!RefId] = RespPerson
	from cat.Warehouses w
	where w.TenantId = @TenantId;

	select [!TPerson!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Warehouses w 
		inner join cat.Agents a on a.TenantId = w.TenantId and w.RespPerson = a.Id
	where w.TenantId = @TenantId;
end
go
------------------------------------------------
create or alter procedure cat.[Warehouse.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Warehouse!TWarehouse!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[RespPerson!TPerson!RefId] = RespPerson
	from cat.Warehouses c
	where c.TenantId = @TenantId and c.Id = @Id;

	select [!TPerson!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Warehouses w 
		inner join cat.Agents a on a.TenantId = w.TenantId and w.RespPerson = a.Id
	where w.TenantId = @TenantId and w.Id = @Id;
end
go
-------------------------------------------------
drop procedure if exists cat.[Warehouse.Metadata];
drop procedure if exists cat.[Warehouse.Update];
drop type if exists cat.[Warehouse.TableType];
go
-------------------------------------------------
create type cat.[Warehouse.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	RespPerson bigint
)
go
------------------------------------------------
create or alter procedure cat.[Warehouse.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Warehouse cat.[Warehouse.TableType];
	select [Warehouse!Warehouse!Metadata] = null, * from @Warehouse;
end
go
------------------------------------------------
create or alter procedure cat.[Warehouse.Update]
@TenantId int = 1,
@UserId bigint,
@Warehouse cat.[Warehouse.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Warehouses as t
	using @Warehouse as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.RespPerson = s.RespPerson
	when not matched by target then insert
		(TenantId, [Name], Memo, RespPerson) values
		(@TenantId, s.[Name], s.Memo, s.RespPerson)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Warehouse.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
