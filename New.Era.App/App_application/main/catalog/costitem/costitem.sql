/* COSTITEM */
------------------------------------------------
drop procedure if exists cat.[CostItem.Metadata];
drop procedure if exists cat.[CostItem.Update];
drop type if exists cat.[CostItem.TableType];
go
------------------------------------------------
create or alter procedure cat.[CostItem.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CostItems!TCostItem!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.CostItems pk
	where TenantId = @TenantId and Void = 0
	order by pk.Id;
end
go
------------------------------------------------
create or alter procedure cat.[CostItem.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CostItem!TCostItem!Object] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.CostItems pk
	where TenantId = @TenantId and Id = @Id;
end
go
---------------------------------------------
create type cat.[CostItem.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[CostItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @CostItem cat.[CostItem.TableType];
	select [CostItem!CostItem!Metadata] = null, * from @CostItem;
end
go
---------------------------------------------
create or alter procedure cat.[CostItem.Update]
@TenantId int = 1,
@UserId bigint,
@CostItem cat.[CostItem.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.CostItems as t
	using @CostItem as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[CostItem.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[CostItem.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.CostItems set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go


