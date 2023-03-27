

------------------------------------------------
create or alter procedure app.[Task.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [States!TState!Array] = null, [Id!!Id] = ts.Id, [Name!!Name] = ts.[Name],
		ts.Color, ts.Memo
	from app.TaskStates ts
	where ts.TenantId = @TenantId and ts.Void = 0
	order by ts.Id;

	select [Tasks!TTask!Array] = null, [Id!!Id] = t.Id, t.[Text],  t.[Notice],
		[Assignee!TUser!RefId] = t.Assignee,  [Project!TProject!RefId] = t.Project,
		[DateCreated!!Utc] = t.UtcDateCreated, [DateComplete!!Utc] = t.UtcDateComplete,
		[State.Id!TState!Id] = t.[State], [State.Name!TState!Name] = ts.[Name], [State.Color!TState!] = ts.[Color],
		[UserName] = N'Петренко Василь'
	from app.Tasks t 
		inner join app.TaskStates ts on t.TenantId = ts.TenantId and t.[State] = ts.Id
	where t.TenantId = @TenantId and t.Void = 0
	order by t.[State], t.[UtcDateCreated]
end
go
------------------------------------------------
create or alter procedure app.[Task.SetState]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@State bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update app.Tasks set [State] = @State where TenantId = @TenantId and Id = @Id;

	select [State!TState!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Color
	from app.TaskStates where TenantId = @TenantId and Id = @State;
end
go