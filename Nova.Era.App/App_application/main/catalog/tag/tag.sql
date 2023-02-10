/* Tag */
------------------------------------------------
create or alter procedure cat.[Tag.For]
@TenantId int = 1,
@UserId bigint,
@For nvarchar(32),
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Tags!TTag!Array] = null,
		[Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color
	from cat.Tags t
	where t.TenantId = @TenantId and t.[For] = @For and t.Void = 0
	order by t.Id;
end
go
------------------------------------------------
create or alter procedure cat.[Tags.Load]
@TenantId int = 1,
@UserId bigint,
@For nvarchar(32),
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Tags!TTag!Array] = null,
		[Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color, t.[Memo], [For] = @For
	from cat.Tags t
	where t.TenantId = @TenantId and t.[For] = @For and t.Void = 0
	order by t.Id;

	select [Params!TParam!Object] = null, [For] = @For;
end
go
-------------------------------------------------
drop procedure if exists cat.[Tags.Metadata];
drop procedure if exists cat.[Tags.Update];
drop type if exists cat.[Tag.TableType];
go
-------------------------------------------------
create type cat.[Tag.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Memo] nvarchar(255),
	[For] nvarchar(32)
)
go

------------------------------------------------
create or alter procedure cat.[Tags.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Tag cat.[Tag.TableType];
	select [Tags!Tags!Metadata] = null, * from @Tag;
end
go
------------------------------------------------
create or alter procedure cat.[Tags.Update]
@TenantId int = 1,
@UserId bigint,
@Tags cat.[Tag.TableType] readonly,
@For nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	merge cat.Tags as t
	using @Tags as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Color] = s.[Color]
	when not matched by target then insert
		(TenantId,  [For], [Name], Color, Memo) values
		(@TenantId, @For, s.[Name], s.Color, s.Memo)
	when not matched by source and t.[For] = @For then update set
		t.Void = 1;
	exec cat.[Tags.Load] @TenantId = @TenantId, @UserId = @UserId, @For = @For;
end
go