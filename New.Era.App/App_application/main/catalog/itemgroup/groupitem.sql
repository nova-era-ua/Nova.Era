/* ITEM GROUPING */
------------------------------------------------
create or alter procedure cat.[GroupItem.Index]
@TenantId int = 1,
@UserId bigint,
@Hierarchy bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- default filter
	--if @Hierarchy is null
		--select top(1) @Hierarchy = Id from cat.ItemTree where @TenantId = @TenantId and Void = 0 and Parent = 0 and Id <> 0;

	with T(Id, [Name], Icon, HasChildren)
	as (
		select Id, [Name], Icon = N'folders-outline',
			HasChildren= case when exists(
				select 1 from cat.ItemTree it where it.Void = 0 and it.Parent = t.Id 
					and it.TenantId = @TenantId and t.TenantId = @TenantId
			) then 1 else 0 end
		from cat.ItemTree t
			where t.TenantId = @TenantId and t.Void = 0 and t.Id <> 0 and t.Parent = 0 and t.Id = t.[Root]
	)
	select [Groups!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon, [IsRoot] = cast(1 as bit),
		/*nested folders - lazy*/
		[Items!TGroup!Items] = null, 
		/* marker: subfolders exist */
		[HasItems!!HasChildren] = HasChildren
	from T
	order by [Id];

	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where 
	TenantId = @TenantId and Void = 0 and Id <> 0 and [Root] = Id and [Parent] = 0;

	select [!$System!] = null,
		[!Groups.Hierarchy!Filter] = @Hierarchy;
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Expand]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Hierarchy bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Items!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon = N'folder-outline',
		[Items!TGroup!Items] = null,
		[HasItems!!HasChildren] = case when exists(select 1 from cat.ItemTree c where c.Void=0 and c.Parent=a.Id) then 1 else 0 end
	from cat.ItemTree a where Parent = @Id and Void=0;
end
go
------------------------------------------------
create or alter procedure cat.[GroupItem.Browse.Index]
@TenantId int = 1,
@UserId bigint,
@Hierarchy bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with T(Id, Parent, [Level])
	as (
		select it.Id, cast(null as bigint), 0
		from cat.ItemTree it
			where it.TenantId = @TenantId and it.Void = 0 and it.Parent = @Hierarchy and it.[Root] <> it.Id
		union all 
		select it.Id, it.Parent, T.[Level] + 1
		from T inner join cat.ItemTree it on it.TenantId = @TenantId and T.Id = it.Parent
		where it.TenantId = @TenantId and it.Void = 0
	)
	select [Groups!TGroup!Tree] = null, [Id!!Id] = it.Id, [Name!!Name] = it.[Name], Icon = N'folder-outline',
		[Group!TGroup.Items!ParentId] = T.Parent,
		[Items!TGroup!Items] = null
	from T
		inner join cat.ItemTree it on it.TenantId = @TenantId and it.Id = T.Id
	order by T.[Level], it.[Id];
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Parent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	if @Parent is null
		select @Parent = [Parent] from cat.ItemTree where @TenantId = @TenantId and Id=@Id;

	select [Group!TGroup!Object] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name],
		[ParentGroup.Id!TParentGroup!Id] = t.Parent, [ParentGroup.Name!TParentGroup!Name] = p.[Name]
	from cat.ItemTree t
		inner join cat.ItemTree p on t.TenantId = p.TenantId and t.Parent = p.Id
	where t.TenantId=@TenantId and t.Id = @Id and t.Void = 0;

	select [ParentGroup!TParentGroup!Object] = null,  [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree 
	where Id=@Parent and TenantId = @TenantId;
end
go
------------------------------------------------
create or alter procedure cat.[HierarchyItem.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Group!TGroup!Object] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name]
	from cat.ItemTree t
	where t.TenantId=@TenantId and t.Id = @Id and t.Void = 0;
end
go
------------------------------------------------
drop procedure if exists cat.[GroupItem.Metadata];
drop procedure if exists cat.[GroupItem.Update];
drop procedure if exists cat.[HierarchyItem.Metadata];
drop procedure if exists cat.[HierarchyItem.Update];
drop type if exists cat.[GroupItem.TableType];
go
------------------------------------------------
create type cat.[GroupItem.TableType]
as table(
	Id bigint null,
	ParentGroup bigint,
	[Name] nvarchar(255)
)
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Group [GroupItem.TableType];
	select [Group!Group!Metadata] = null, * from @Group;
end
go
-------------------------------------------------
create or alter procedure cat.[HierarchyItem.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Group [GroupItem.TableType];
	select [Group!Group!Metadata] = null, * from @Group;
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Update]
@TenantId int = 1,
@UserId bigint,
@Group [GroupItem.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output table(op sysname, id bigint);
	declare @Root bigint;
	select top(1) @Root = [Root] from cat.ItemTree it
	inner join @Group g on it.TenantId = @TenantId and it.Id = g.ParentGroup;

	merge cat.ItemTree as t
	using @Group as s
	on (t.Id = s.Id and t.TenantId = @TenantId)
	when matched then
		update set 
			t.[Name] = s.[Name]
	when not matched by target then 
		insert (TenantId, [Root], Parent, [Name])
		values (@TenantId, @Root, s.ParentGroup, s.[Name])
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	select [Group!TGroup!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon=N'folder-outline',
		ParentFolder = Parent
	from cat.ItemTree
	where  TenantId = @TenantId and Id=@RetId;
end
go
-------------------------------------------------
create or alter procedure cat.[HierarchyItem.Update]
@TenantId int = 1,
@UserId bigint,
@Group [GroupItem.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output table(op sysname, id bigint);

	begin tran;
	merge cat.ItemTree as t
	using @Group as s
	on (t.Id = s.Id and t.TenantId = @TenantId)
	when matched then
		update set 
			t.[Name] = s.[Name]
	when not matched by target then 
		insert (TenantId, [Root], Parent, [Name])
		values (@TenantId, 0, 0, s.[Name])
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	update cat.ItemTree set [Root] = @RetId where TenantId=@TenantId and Id=@RetId and Parent = 0;
	commit tran;

	select [Group!TGroup!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], IsRoot = 1,
		Icon=N'folders-outline'
	from cat.ItemTree
	where  TenantId = @TenantId and Id=@RetId;
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Hierarchies.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Groups!TGroup!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where TenantId = @TenantId and Id <> 0 and Parent = 0 and Id = [Root]
end
go
-------------------------------------------------
create or alter procedure cat.[GroupItem.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	begin tran;

	delete from cat.ItemTreeElems where TenantId = @TenantId and Parent = @Id;
	delete from cat.ItemTree where TenantId = @TenantId and Id = @Id;

	commit tran;
end
go