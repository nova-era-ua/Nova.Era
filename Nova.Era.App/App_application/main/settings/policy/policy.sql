-- DEBUG
------------------------------------------------
create or alter procedure app.[Policy.Load]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Policy!TPolicy!Object] = null, [Id!!Id] = 1, CheckRems, CheckPayments,
		[AccPlanRems!TAccount!RefId] = AccPlanRems,
		[AccPlanPayments!TAccount!RefId] = AccPlanPayments
	from app.Settings where TenantId = @TenantId;

	select [Accounts!TAccount!Array] = null, [Id!!Id] = Id, Code, [Name!!Name] = a.[Name]
	from acc.Accounts a
	where a.TenantId = @TenantId and Void = 0 and [Plan] is null and Parent is null and Void = 0
	order by a.Id;
end
go
------------------------------------------------
drop procedure if exists app.[Policy.Metadata];
drop procedure if exists app.[Policy.Update];
drop type if exists app.[Policy.TableType];
go
------------------------------------------------
create type app.[Policy.TableType]
as table (
	CheckRems nchar(1),
	AccPlanRems bigint
)
go
------------------------------------------------
create or alter procedure app.[Policy.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Policy app.[Policy.TableType];
	select [Policy!Policy!Metadata] = null, * from @Policy;
end
go
------------------------------------------------
create or alter procedure app.[Policy.Update]
@TenantId int = 1,
@UserId bigint,
@Policy app.[Policy.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	merge app.Settings as t
	using @Policy as s
	on t.TenantId = @TenantId and t.TenantId = @TenantId
	when matched then update set 
		t.CheckRems = s.CheckRems,
		t.AccPlanRems = s.AccPlanRems
	when not matched by target then insert
		(TenantId, CheckRems, AccPlanRems) values
		(@TenantId, CheckRems, AccPlanRems);

	exec app.[Policy.Load] @TenantId = @TenantId, @UserId = @UserId;
end
go
