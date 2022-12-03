-- Notification
create or alter procedure app.[Navpane.Load]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Notify!TNotify!Object] = null, [Count] = count(*)
	from app.Notifications where TenantId = @TenantId and UserId = @UserId and Done = 0;
end
go
-------------------------------------------------
create or alter procedure app.[Notification.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Mode nvarchar(1) = N'U'
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @notes table(id bigint, rowcnt int, rowno int identity(1, 1));

	insert into @notes(id, rowcnt)
	select n.Id,
		count(*) over()
	from app.Notifications n
	where n.TenantId = @TenantId and n.UserId = @UserId
		and (@Mode = N'U' and Done = 0) or @Mode = 'A'
	order by UtcDateCreated desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Notifications!TNotify!Array] = null, [Id!!Id] = n.Id, n.[Text],
		n.Done, n.Link, n.LinkUrl, n.Icon, [DateCreated!!Utc] = n.UtcDateCreated,
		[!!RowCount] = t.rowcnt
	from @notes t inner join 
		app.Notifications n on n.TenantId = @TenantId and n.Id = t.id
	order by t.rowno;

	select [!$System!] = null, [!Notifications!Offset] = @Offset, [!Notifications!PageSize] = @PageSize, 
		[!Notifications.Mode!Filter] = @Mode;
end
go
-------------------------------------------------
create or alter procedure app.[Notification.Done]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update app.Notifications set Done = 1 where TenantId = @TenantId and Id = @Id;
end
go
