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

	select [Tasks!TTask!Array] = null, [Id!!Id] = t.Id
	from app.Tasks t 
		left join app.TaskStates ts on ts.TenantId = t.TenantId and ts.Id = t.[State]
	where t.TenantId = @TenantId and Link = @Id and LinkType = @LinkType
	order by t.UtcDateCreated desc;

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

	select [Task!TTask!Object] = null, [Id!!Id] = t.Id, 
	from app.Tasks t 
	where t.TenantId = @TenantId and Link = @Id and LinkType = @LinkType
	order by t.UtcDateCreated desc;

	select [Params!TParam!Object] = null, LinkId = @LinkId, LinkType = @LinkType, LinkUrl = @LinkUrl;
end
go