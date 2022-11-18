------------------------------------------------
drop procedure if exists cat.[Item.Variant.Create.Metadata];
drop procedure if exists cat.[Item.Variant.Create.Update];
drop type if exists cat.[Item.Variant.Item.TableType];
drop type if exists cat.[Item.Variant.Variant.TableType];
go
------------------------------------------------
create type cat.[Item.Variant.Item.TableType] as table
(
	[GUID] uniqueidentifier,
	Id bigint
)
go
------------------------------------------------
create type cat.[Item.Variant.Variant.TableType] as table
(
	ParentGUID uniqueidentifier,
	Id1 bigint,
	Id2 bigint,
	Id3 bigint,
	[Name] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Create.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as 
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Item!TItem!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode,
		[Option1!TOption!RefId] = cast(null as bigint),
		[Option2!TOption!RefId] = cast(null as bigint),
		[Option3!TOption!RefId] = cast(null as bigint),
		[Variants!TVariant!Array] = null
	from cat.Items i
	where TenantId = @TenantId and Id = @Id;

	select [Options!TOption!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[Values!TOptionValue!Array] = null
	from cat.ItemOptions 
	where TenantId = @TenantId
	order by Id;

	select [!TOptionValue!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[!TOption.Values!ParentId] = [Option], Checked = cast(1 as bit)
	from cat.ItemOptionValues
	where TenantId = @TenantId;

	select [!TVariant!Array] = null, 
		[Id1] = cast(null as bigint), [Name1] = cast(null as nvarchar),
		[Id2] = cast(null as bigint), [Name2] = cast(null as nvarchar),
		[Id3] = cast(null as bigint), [Name3] = cast(null as nvarchar),
		Article = cast(null as nvarchar),
		[!TItem.Variants!ParentId] = @Id
	where 0 <> 0;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Create.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Item cat.[Item.Variant.Item.TableType];
	declare @Variants cat.[Item.Variant.Variant.TableType];

	select [Item!Item!Metadata] = null, * from @Item;
	select [Variants!Item.Variants!Metadata] = null, * from @Variants;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Create.Update]
@TenantId int = 1,
@UserId bigint,
@Item cat.[Item.Variant.Item.TableType] readonly,
@Variants cat.[Item.Variant.Variant.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @itemid bigint;
	declare @itemname nvarchar(255);
	declare @role bigint;

	select @itemid = i.Id, @itemname = i.[Name], @role = i.[Role]
	from @Item t inner join cat.Items i on i.TenantId = @TenantId and i.Id = t.Id;

	declare @vars table(id bigint, [name] nvarchar(255));

	begin tran;
	insert into cat.ItemVariants(TenantId, Option1, Option2, Option3, [Name])
	output inserted.Id, inserted.[Name] into @vars(id, [name])
	select @TenantId, nullif(Id1, 0), nullif(Id2, 0), nullif(Id3, 0), [Name] from @Variants v;

	insert into cat.Items(TenantId, Parent, [Role], [Name], Variant)
	select @TenantId, @itemid, @role, @itemname + N' [' + v.[name] + N']', v.id
	from @vars v;
	commit tran;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @vart bigint;
	select @vart = Variant from cat.Items where TenantId = @TenantId and Id = @Id;

	select [Variant!TVariant!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name],
		i.Barcode, i.Article, i.Memo,
		[Option1!TOption!RefId] = iv.Option1, [Option2!TOption!RefId] = iv.Option2, [Option3!TOption!RefId] = iv.Option3,
		[ParentName] = p.[Name]
	from cat.Items i
		inner join cat.Items p on i.TenantId = p.TenantId and i.Parent = p.Id
		left join cat.ItemVariants iv on i.TenantId = iv.TenantId and i.Variant = iv.Id
		left join cat.ItemOptionValues ov1 on ov1.TenantId = iv.TenantId and iv.Option1 = ov1.Id
	where i.TenantId = @TenantId and i.Id = @Id;

	select [!TOption!Map] = null, [Id!!Id] = ov.Id, [Name!!Name] = o.[Name], [Value] = ov.[Name]
	from cat.ItemOptionValues ov 
		inner join cat.ItemVariants iv on ov.TenantId = iv.TenantId and ov.Id in (iv.Option1, iv.Option2, iv.Option3)
		inner join cat.ItemOptions o on iv.TenantId = o.TenantId and o.Id = ov.[Option]
	where iv.Id = @vart
end
go
------------------------------------------------
drop procedure if exists cat.[Item.Variant.Metadata];
drop procedure if exists cat.[Item.Variant.Update];
drop type if exists cat.[Item.Variant.TableType];
go
------------------------------------------------
create type cat.[Item.Variant.TableType] as table
(
	[Id] bigint,
	[Name] nvarchar(255),
	Article nvarchar(32),
	Barcode nvarchar(32),
	Memo nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Variant cat.[Item.Variant.TableType];
	select [Variant!Variant!Metadata] = null, * from @Variant;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Variant.Update]
@TenantId int = 1,
@UserId bigint,
@Variant cat.[Item.Variant.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	merge cat.Items as t
	using @Variant as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.Article = s.Article,
		t.Barcode = s.Barcode,
		t.Memo = s.Memo;

	-- simple variant for update UI
	select [Variant!TVariant!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name],
		i.Barcode, i.Article, i.Memo, i.IsVariant
	from cat.Items i inner join @Variant v on i.TenantId = @TenantId and i.Id = v.Id;
end
go








