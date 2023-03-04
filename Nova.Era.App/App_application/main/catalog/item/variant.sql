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
	Id1 bigint,
	Id2 bigint,
	Id3 bigint,
	[Name] nvarchar(255),
	[Article] nvarchar(32),
	[Barcode] nvarchar(32)
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
		[Variants!TVariant!Array] = null,
		[Result!TResult!Array] = null
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
	where TenantId = @TenantId and Void = 0;

	select [!TVariant!Array] = null, 
		[Id1] = cast(null as bigint), [Name1] = cast(null as nvarchar(255)),
		[Id2] = cast(null as bigint), [Name2] = cast(null as nvarchar(255)),
		[Id3] = cast(null as bigint), [Name3] = cast(null as nvarchar(255)),
		Article = cast(null as nvarchar(32)), Barcode = cast(null as nvarchar(32)),
		[!TItem.Variants!ParentId] = @Id
	where 0 <> 0;

	select [!TResult!Array] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Article, v.Barcode, v.Memo,
		v.IsVariant, [!TItem.Result!ParentId] = @Id
	from cat.Items v 
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
	declare @unit bigint;

	select @itemid = i.Id, @itemname = i.[Name], @role = i.[Role], @unit = i.Unit
	from @Item t inner join cat.Items i on i.TenantId = @TenantId and i.Id = t.Id;

	declare @vars table(id bigint, [name] nvarchar(255), [article] nvarchar(32), barcode nvarchar(32));

	begin tran;
	-- insert into @vars with source columns
	merge cat.ItemVariants as t
	using @Variants as s
	on (0 <> 0)
	when not matched then insert
		(TenantId, Option1, Option2, Option3, [Name]) values
		(@TenantId, nullif(Id1, 0), nullif(Id2, 0), nullif(Id3, 0), [Name])
	output inserted.Id, inserted.[Name], s.Article, s.Barcode into @vars(id, [name], article, barcode);

	insert into cat.Items(TenantId, Parent, [Role], Unit, [Name], Variant, Article, Barcode)
	select @TenantId, @itemid, @role, @unit, @itemname + N' [' + v.[name] + N']', v.id, v.article, v.barcode
	from @vars v
	commit tran;

	select [Item!TItem!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode,
		[Result!TResult!Array] = null
	from cat.Items i
	where TenantId = @TenantId and Id = @itemid;

	select [!TVariant!Array] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Article, v.Barcode, v.Memo,
		[Role.Id!TItemRole!Id] = v.[Role], [Role.Name!TItemRole!Name] = ir.[Name], [Role.Color!TItemRole!] = ir.Color,
		v.IsVariant, [!TItem.Result!ParentId] = @itemid
	from cat.Items v 
		left join cat.ItemRoles ir on v.TenantId = ir.TenantId and v.[Role] = ir.Id
	where v.TenantId = @TenantId and v.Parent = @itemid and v.Void = 0 and v.IsVariant = 1;
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
		i.Barcode, i.Article, i.Memo, i.IsVariant,
		[Option1!TOption!RefId] = iv.Option1, [Option2!TOption!RefId] = iv.Option2, [Option3!TOption!RefId] = iv.Option3,
		[ParentName] = p.[Name],
		[Role.Id!TItemRole!Id] = i.[Role], [Role.Name!TItemRole!Name] = ir.[Name], [Role.Color!TItemRole!] = ir.Color
	from cat.Items i
		inner join cat.Items p on i.TenantId = p.TenantId and i.Parent = p.Id
		left join cat.ItemVariants iv on i.TenantId = iv.TenantId and i.Variant = iv.Id
		left join cat.ItemOptionValues ov1 on ov1.TenantId = iv.TenantId and iv.Option1 = ov1.Id
		left join cat.ItemRoles ir on ir.TenantId = i.TenantId and i.[Role] = ir.Id
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
		i.Barcode, i.Article, i.Memo, i.IsVariant,
		[Role.Id!TItemRole!Id] = i.[Role], [Role.Name!TItemRole!Name] = ir.[Name], [Role.Color!TItemRole!] = ir.Color
	from cat.Items i inner join @Variant v on i.TenantId = @TenantId and i.Id = v.Id
	inner join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
end
go








