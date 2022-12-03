/* TASK.Partial */
-------------------------------------------------
create or alter procedure app.[Task.Partial.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@LinkType nvarchar(64)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Tasks!TTask!Array] = null, [Id!!Id] = 0
end
go
