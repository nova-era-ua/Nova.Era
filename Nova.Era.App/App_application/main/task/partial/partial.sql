/* TASK.Partial */
-------------------------------------------------
create or alter procedure app.[Task.Partial.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@LinkType nvarchar(64),
@LinkUrl nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Tasks!TTask!Array] = null, [Id!!Id] = t.Id, t.[Text], t.Notice, [DateCreated!!Utc] = t.UtcDateComplete,
		[State!TState!RefId] = t.[State], [Assignee!TUser!RefId] = t.Assignee
	from app.Tasks t 
	where t.TenantId = @TenantId and Link = @Id and LinkType = @LinkType
	order by t.UtcDateCreated desc;

	select [!TState!Map] = null, [Id!!Id] = ts.Id, [Name!!Name] = [Name], Color
	from app.TaskStates ts
	where ts.TenantId = @TenantId and ts.Void = 0
	order by ts.[Order];

	select [Params!TParam!Object] = null, LinkType = @LinkType, LinkId = @Id, LinkUrl = @LinkUrl
end
go


-------------------------------------------------
create or alter procedure app.[Task.Partial.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@LinkId bigint = null,
@LinkType nvarchar(64) = null,
@LinkUrl nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Task!TTask!MainObject] = null, [Id!!Id] = t.Id, t.[Text], [Assignee!TUser!RefId] = t.Assignee,
		[State!TState!RefId] = t.[State], t.Notice, [Project!TProject!RefId] = t.Project,
		LinkId = Link, LinkType, LinkUrl, [DateCreated!!Utc] = t.UtcDateComplete
	from app.Tasks t 
	where t.TenantId = @TenantId and Id = @Id;

	select [Params!TParam!Object] = null, LinkId = @LinkId, LinkType = @LinkType, LinkUrl = @LinkUrl;

	select [States!TState!Map] = null, [Id!!Id] = ts.Id, [Name!!Name] = [Name], Color
	from app.TaskStates ts
	where ts.TenantId = @TenantId and ts.Void = 0
	order by ts.[Order];
end
go
-------------------------------------------------
drop procedure if exists app.[Task.Partial.Metadata];
drop procedure if exists app.[Task.Partial.Update];
drop type if exists app.[Task.TableType];
go
-------------------------------------------------
create type app.[Task.TableType] as table
(
	Id bigint,
	[Text] nvarchar(255),
	Notice nvarchar(255),
	[State] bigint,
	LinkId bigint,
    LinkType nvarchar(64),
    LinkUrl nvarchar(255)
)
go
-------------------------------------------------
create or alter procedure app.[Task.Partial.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Task app.[Task.TableType];
	select [Task!Task!Metadata] = null, * from @Task;
end
go
-------------------------------------------------
create or alter procedure app.[Task.Partial.Update]
@TenantId int = 1,
@UserId bigint,
@Task app.[Task.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge app.Tasks as t
	using @Task as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Text] =  s.[Text],
		t.[Notice] = s.[Notice],
		t.Void = 0
	when not matched by target then insert
		(TenantId, [State], Link, LinkType, LinkUrl, [Text], [Notice]) values
		(@TenantId, s.[State], s.LinkId, s.LinkType, s.LinkUrl, s.[Text], [Notice])
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec app.[Task.Partial.Load] @UserId = @UserId, @Id = @id;
end
go
