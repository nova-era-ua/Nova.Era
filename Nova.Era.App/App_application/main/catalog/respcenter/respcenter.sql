/* RESPCENTER */
------------------------------------------------
drop procedure if exists cat.[RespCenter.Metadata];
drop procedure if exists cat.[RespCenter.Update];
drop type if exists cat.[RespCenter.TableType];
go
------------------------------------------------
create or alter procedure cat.[RespCenter.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [RespCenters!TRespCenter!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.RespCenters pk
	where TenantId = @TenantId and Void = 0
	order by pk.Id;
end
go
------------------------------------------------
create or alter procedure cat.[RespCenter.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [RespCenter!TRespCenter!Object] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.RespCenters pk
	where TenantId = @TenantId and Id = @Id;
end
go
---------------------------------------------
create type cat.[RespCenter.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[RespCenter.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @RespCenter cat.[RespCenter.TableType];
	select [RespCenter!RespCenter!Metadata] = null, * from @RespCenter;
end
go
---------------------------------------------
create or alter procedure cat.[RespCenter.Update]
@TenantId int = 1,
@UserId bigint,
@RespCenter cat.[RespCenter.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.RespCenters as t
	using @RespCenter as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[RespCenter.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[RespCenter.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from doc.Documents where TenantId = @TenantId and RespCenter = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.RespCenters set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go
------------------------------------------------
create or alter procedure cat.[RespCenter.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [RespCenters!TRespCenter!Array] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name], r.Memo
	from cat.RespCenters r
	where TenantId = @TenantId and Void = 0 and
		([Name] like @fr or Memo like @fr)
	order by r.[Name];
end
go


