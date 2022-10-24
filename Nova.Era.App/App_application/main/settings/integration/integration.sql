-- integration
------------------------------------------------
drop procedure if exists app.[Integration.Metadata];
drop procedure if exists app.[Integration.Update];
drop type if exists app.[Integration.TableType];
go
------------------------------------------------
create type app.[Integration.TableType] as table
(
	Id bigint,
	[Key] nvarchar(255),
	[Active] bit,
	[Name] nvarchar(255),
	ApiKey nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure app.[Integration.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Sources!TSource!Array] = null, [Id!!Id] = s.[Key],
		[Integrations!TIntegration!Array] = null
	from app.Integrations i
		inner join app.IntegrationSources s on i.Source = s.Id
	where TenantId = @TenantId
	group by s.[Key]
	order by s.[Key];

	select [!TIntegration!Array] = null, [Id!!Id] = i.Id, i.Active, i.[Name],
		s.Logo, SetupUrl, i.[Memo], [SourceName] = s.[Name],
		[!TSource.Integrations!ParentId] = s.[Key]
	from app.Integrations i
		inner join app.IntegrationSources s on i.Source = s.Id
	where TenantId = @TenantId
	order by i.Id;
end
go
------------------------------------------------
create or alter procedure app.[Integration.Browse.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Sources!TSource!Array] = null, Id = s.Id, [Key] = s.[Key], s.[Name], s.Logo,
		IntName = cast(null as nvarchar(255))
	from app.IntegrationSources s
	order by s.Id;
end
go
------------------------------------------------
create or alter procedure app.[Integration.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Integration!TIntegration!Object] = null, [Id!!Id] = i.Id,
		i.[Name], i.[Memo], i.Active, i.Source, i.ApiKey,
		SourceName = s.[Name], s.SetupUrl, s.Icon, s.[Key], s.Logo
	from app.Integrations i
		inner join app.IntegrationSources s on i.Source = s.Id
	where TenantId = @TenantId and i.Id = @Id;
end
go
------------------------------------------------
create or alter procedure app.[Integration.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Integration app.[Integration.TableType];
	select [Integration!Integration!Metadata] = null, * from @Integration;
end
go
------------------------------------------------
create or alter procedure app.[Integration.Update]
@TenantId int = 1,
@UserId bigint,
@Integration app.[Integration.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Integration for xml auto);
	throw 60000, @xml, 0;
	*/
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge app.Integrations as t
	using @Integration as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name],
		t.Active = s.Active, 
		t.ApiKey = s.ApiKey,
		t.[Memo] = s.[Memo]
	output $action, inserted.Id into @output (op, id);

	select @id = id from @output;

	exec app.[Integration.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

------------------------------------------------
create or alter procedure app.[Integration.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	delete from app.Integrations where TenantId = @TenantId and Id = @Id;
end
go

------------------------------------------------
create or alter procedure app.[Integration.Add]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Key nvarchar(16),
@Name nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @newid bigint;

	insert into app.Integrations(TenantId, [Source], [Key], [Name])
	output inserted.Id into @rtable(id)
	values (@TenantId, @Id, @Key, @Name);
	select @newid = id from @rtable;

	exec app.[Integration.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @newid;
end
go


