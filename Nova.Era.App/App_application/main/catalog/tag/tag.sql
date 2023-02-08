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
create or alter procedure cat.[Tag.Index]
@TenantId int = 1,
@UserId bigint,
@For nvarchar(32),
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Tags!TTag!Array] = null,
		[Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color, t.[Memo]
	from cat.Tags t
	where t.TenantId = @TenantId and t.[For] = @For and t.Void = 0
	order by t.Id;
end
go
