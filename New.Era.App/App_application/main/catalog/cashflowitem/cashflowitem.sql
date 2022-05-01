/* CASHFLOWITEM */
------------------------------------------------
drop procedure if exists cat.[CashFlowItem.Metadata];
drop procedure if exists cat.[CashFlowItem.Update];
drop type if exists cat.[CashFlowItem.TableType];
go
------------------------------------------------
create or alter procedure cat.[CashFlowItem.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CashFlowItems!TCashFlowItem!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.CashFlowItems pk
	where TenantId = @TenantId and Void = 0
	order by pk.Id;
end
go
------------------------------------------------
create or alter procedure cat.[CashFlowItem.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CashFlowItem!TCashFlowItem!Object] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.CashFlowItems pk
	where TenantId = @TenantId and Id = @Id;
end
go
---------------------------------------------
create type cat.[CashFlowItem.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[CashFlowItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @CashFlowItem cat.[CashFlowItem.TableType];
	select [CashFlowItem!CashFlowItem!Metadata] = null, * from @CashFlowItem;
end
go
---------------------------------------------
create or alter procedure cat.[CashFlowItem.Update]
@TenantId int = 1,
@UserId bigint,
@CashFlowItem cat.[CashFlowItem.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.CashFlowItems as t
	using @CashFlowItem as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[CashFlowItem.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[CashFlowItem.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.CashFlowItems set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go


