/* Item */
drop type if exists cat.[view_Items.TableType];
go
-------------------------------------------------
create type cat.[view_Items.TableType]
as table (
	[Id!!Id] bigint,
	[Name!!Name] nvarchar(255),
	Article nvarchar(32),
	Barcode nvarchar(32),
	Memo nvarchar(32),
	[Unit.Id!TUnit!Id] bigint, 
	[Unit.Short!TUnit] nvarchar(8),
	[Role!TItemRole!RefId] bigint,
	[!TenantId] int, 
	[!IsStock] bit,
	Price float,
	Rem float,
	[!RowNo] int,
	[!!RowCount] int
);
go
-------------------------------------------------
create or alter view cat.view_Items
as
select [Id!!Id] = i.Id, 
	[Name!!Name] = i.[Name], i.Article, i.Barcode, i.Memo,
	[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
	[Role!TItemRole!RefId] = i.[Role],
	[!TenantId] = i.TenantId, [!IsStock] = ir.IsStock, Price = null, Rem = null, [!RowNo] = 0, [!!RowCount] = 0
from cat.Items i
	left join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
	left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
where i.Void = 0;
go
-------------------------------------------------
create or alter view cat.view_ItemRoles
as
select [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Color, ir.IsStock, ir.Kind,
	[CostItem.Id!TCostItem!Id] = ir.CostItem, [CostItem.Name!TCostItem!Name] = ci.[Name],
	[!TenantId] = ir.TenantId
from cat.ItemRoles ir
	left join cat.CostItems ci on ir.TenantId = ci.TenantId and ir.CostItem =ci.Id;
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Index]
@TenantId int = 1,
@UserId bigint,
@Group bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	if @Group is null
		select top(1) @Group = Id from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id = [Root] and Id <> 0;

	with T(Id, _order, [Name], HasChildren, Icon)
	as (
		select Id = -1, 0, [Name] = N'@[NoGrouping]', 0, Icon=N'package-outline'
		union all
		-- hack = negative!
		select Id = -@Group, 2, [Name] = N'@[WithoutGroup]', 0, Icon=N'ban' where @Group is not null
		union all
		select Id, 1, [Name],
			HasChildren= case when exists(
				select 1 from cat.ItemTree it where it.Void = 0 
				and it.Parent = t.Id and it.TenantId = @TenantId and t.TenantId = @TenantId
			) then 1 else 0 end,
			Icon = N'folder-outline'
		from cat.ItemTree t
			where t.TenantId = @TenantId and t.Void = 0 and t.Parent = @Group
	)
	select [Groups!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Icon,
		/*nested folders - lazy*/
		[Items!TGroup!Items] = null, 
		/* marker: subfolders exist */
		[HasSubItems!!HasChildren] = HasChildren,
		/*nested items (not folders!) */
		[Elements!TItem!LazyArray] = null
	from T
	order by _order, [Id];

	-- Elements definition
	select [!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], 
		i.Article, i.Barcode, i.Memo, [Role!TItemRole!RefId] = i.[Role], i.IsVariant,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short
	from cat.Items i
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	where 0 <> 0;

	select [!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Color, ir.IsStock
	from cat.ItemRoles ir 
	where 0 <> 0;

	-- filters
	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id <> Parent and Id <> 0;

	select [!$System!] = null,
		[!Hierarchies.Group!Filter] = @Group
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Expand]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Group bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Items!TGroup!Tree] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[Items!TGroup!Items] = null,
		[HasSubItems!!HasChildren] = case when exists(select 1 from cat.ItemTree c where c.Void=0 and c.Parent=a.Id) then 1 else 0 end,
		Icon = N'folder-outline'
	from cat.ItemTree a where Parent = @Id and Void=0;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Elements]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null, -- GroupId
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Asc nvarchar(10), @Desc nvarchar(10), @RowCount int;
	declare @fr nvarchar(255);

	set @Asc = N'asc'; set @Desc = N'desc';
	set @Dir = lower(isnull(@Dir, @Asc));
	set @Order = lower(@Order);
	set @fr = N'%' + @Fragment + N'%';

	declare @items table(rowno int identity(1, 1), id bigint, unit bigint, [role] bigint, rowcnt int);
	--@Id = ite.Parent or 
	insert into @items(id, unit, [role], rowcnt)
	select i.Id, i.Unit, i.[Role],
		count(*) over()
	from cat.Items i
		left join cat.ItemTreeElems ite on i.TenantId = ite.TenantId and i.Id = ite.Item
	where i.TenantId = @TenantId and i.Void = 0
		and (@Id = -1 or @Id = ite.Parent or (@Id < 0 and i.Id not in (
			select Item from cat.ItemTreeElems intbl where intbl.TenantId = @TenantId and intbl.[Root] = -@Id /*hack:negative*/
		)))
		and (@fr is null or [Name] like @fr or Memo like @fr or Article like @fr or Barcode like @fr)
	group by i.Id, i.Unit, i.[Name], i.Article, i.Barcode, i.Memo, i.[Role]
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then i.[Name]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then i.[Name]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order 
				when N'id' then i.Id
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then i.Id
			end
		end desc,
		i.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Elements!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], 
		i.Article, i.Barcode, i.Memo, [Role!TItemRole!RefId] = i.[Role], i.IsVariant,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short, 
		[!!RowCount]  = t.rowcnt
	from @items t inner join cat.Items i on i.TenantId = @TenantId and i.Id = t.id
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	order by t.rowno;

	with R([role]) as (select [role] from @items group by [role])
	select [!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Color, ir.IsStock
	from cat.ItemRoles ir inner join R on ir.TenantId = @TenantId and ir.Id = R.[role];

	-- system data
	select [!$System!] = null,
		[!Elements!Offset] = @Offset, [!Elements!PageSize] = @PageSize, 
		[!Elements!SortOrder] = @Order, [!Elements!SortDir] = @Dir,
		[!Elements.Fragment!Filter] = @Fragment;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Plain.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);
	
	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';


	declare @items table(rowno int identity(1, 1), id bigint, unit bigint, rowcnt int);

	insert into @items(id, unit, rowcnt)
	select i.Id, i.Unit, 
		count(*) over()
	from cat.Items i
	where i.TenantId = @TenantId and i.Void = 0
		and (@fr is null or i.Name like @fr or i.FullName like @fr or i.Memo like @fr or i.Article like @fr or i.Barcode like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'id' then i.[Id]
			end
		end asc,
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then i.[Name]
				when N'fullname' then i.[FullName]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then i.[Id]
			end
		end desc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then i.[Name]
				when N'fullname' then i.[FullName]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Items!TItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article, i.Barcode, i.Memo,
		[Role!TItemRole!RefId] = i.[Role], [Unit!TUnit!RefId] = i.Unit,
		[!!RowCount] = t.rowcnt
	from @items t inner join cat.Items i on i.TenantId = @TenantId and t.id = i.Id
	order by t.rowno;

	-- maps
	with T as (select unit from @items group by unit)
	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.[Short]
	from cat.Units u 
		inner join T t on u.TenantId = @TenantId and u.Id = unit;

	-- filter
	select [!$System!] = null, [!Items!Offset] = @Offset, [!Items!PageSize] = @PageSize, 
		[!Items!SortOrder] = @Order, [!Items!SortDir] = @Dir,
		[!Items.Fragment!Filter] = @Fragment;
end
go
------------------------------------------------
drop procedure if exists cat.[Item.Metadata];
drop procedure if exists cat.[Item.Update];
drop type if exists cat.[Item.TableType];
drop type if exists cat.[ItemTreeElem.TableType];
go
------------------------------------------------
create type cat.[Item.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	Article nvarchar(32),
	Barcode nvarchar(32),
	FullName nvarchar(255),
	[Memo] nvarchar(255),
	[Role] bigint,
	Unit bigint,
	Vendor bigint,
	Brand bigint,
	Country nchar(3)
);
go
-------------------------------------------------
create type cat.[ItemTreeElem.TableType]
as table(
	[Group] bigint, -- Parent
	ParentId bigint -- Root
);
go
------------------------------------------------
create or alter procedure cat.[Item.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Item!TItem!Object] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.FullName, i.Article, i.Barcode, i.Memo,
		[Role!TItemRole!RefId] = i.[Role],
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
		[Brand!TBrand!RefId] = i.Brand, [Vendor!TVendor!RefId] = i.Vendor,
		[Country!TCountry!RefId] = i.Country,
		[Variants!TVariant!Array] = null
	from cat.Items i 
		left join cat.Units u on  i.TenantId = u.TenantId and i.Unit = u.Id
	where i.TenantId = @TenantId and i.Id=@Id and i.Void = 0;

	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[Elements!THieElem!Array] = null
	from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id = [Root] and Id <> 0;

	select [!TBrand!Map] = null, [Id!!Id] = b.Id, [Name!!Name] = b.[Name]
	from cat.Brands b
		inner join cat.Items i on b.TenantId = i.TenantId and b.Id = i.Brand
	where i.TenantId = @TenantId and i.Id = @Id;

	select [!TVendor!Map] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name]
	from cat.Vendors v
		inner join cat.Items i on v.TenantId = i.TenantId and v.Id = i.Vendor
	where i.TenantId = @TenantId and i.Id = @Id;

	select [!TCountry!Map] = null, [Id!!Id] = c.Code, [Name!!Name] = c.[Name]
	from cat.Countries c
		inner join cat.Items i on c.TenantId = i.TenantId and c.Code = i.Country
	where i.TenantId = @TenantId and i.Id = @Id;

	select [ItemRoles!TItemRole!Array] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Color, ir.IsStock,
		[CostItem.Id!TCostItem!Id] = ir.CostItem, [CostItem.Name!TCostItem!Name] = ci.[Name],
		[Accounts!TItemRoleAcc!Array] = null
	from cat.ItemRoles ir 
		left join cat.CostItems ci on ir.TenantId = ci.TenantId and ir.CostItem =ci.Id
	where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Item';
	
	select [!THieElem!Array] = null, [!THie.Elements!ParentId] = iti.[Root],
		[Group] = iti.Parent,
		[Path] = cat.fn_GetItemBreadcrumbs(@TenantId, iti.Parent, null)
	from cat.ItemTreeElems iti 
	where TenantId = @TenantId  and iti.Item = @Id;

	select [!TVariant!Array] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name], [!TItem.Variants!ParentId] = v.Parent
	from cat.Items v 
	where v.TenantId = @TenantId and v.Parent = @Id and v.Void = 0;

	-- TItemRoleAcc
	select [!TItemRoleAcc!LazyArray] = null, [Plan] = p.Code, Kind = ak.[Name], Account = a.Code,
		[!TItemRole.Accounts!ParentId] = ira.[Role], PlanName = p.[Name], AccountName = a.[Name]
	from cat.ItemRoleAccounts ira
		inner join cat.ItemRoles ir on ira.TenantId = ir.TenantId and ira.[Role] = ir.Id
		inner join acc.Accounts p on ira.TenantId = p.TenantId and ira.[Plan] = p.Id
		inner join acc.AccKinds ak on ira.TenantId = ak.TenantId and ira.AccKind = ak.Id
		inner join acc.Accounts a on ira.TenantId = a.TenantId and ira.Account = a.Id
	where ira.TenantId = @TenantId and ir.Kind = N'Item'
	order by ira.Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Item cat.[Item.TableType];
	declare @Groups cat.[ItemTreeElem.TableType];
	select [Item!Item!Metadata] = null, * from @Item;
	select [Groups!Item.Hierarchies.Elements!Metadata] = null, * from @Groups;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Update]
@TenantId int = 1,
@UserId bigint,
@Item cat.[Item.TableType] readonly,
@Groups cat.[ItemTreeElem.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Groups for xml auto);
	throw 60000, @xml, 0;
	*/

	declare @output table(op sysname, id bigint);

	begin tran;
	merge cat.Items as t
	using @Item as s
	on (t.Id = s.Id and t.TenantId = @TenantId)
	when matched then
		update set 
			t.[Name] = s.[Name],
			t.FullName = s.FullName,
			t.[Article] = s.[Article],
			t.Barcode = s.Barcode,
			t.Memo = s.Memo,
			t.[Role] = s.[Role],
			t.Unit = s.Unit,
			t.Brand = s.Brand,
			t.Vendor = s.Vendor,
			t.Country = s.Country
	when not matched by target then 
		insert (TenantId, [Name], FullName, [Article], Barcode, Memo, [Role], Unit, Brand, Vendor, Country)
		values (@TenantId, s.[Name], s.FullName, s.Article, s.Barcode, s.Memo, s.[Role], s.Unit, s.Brand, s.Vendor, s.Country)
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	merge cat.ItemTreeElems as t
	using @Groups as s
	on t.TenantId = @TenantId and t.[Root] = s.ParentId and t.[Parent] = s.[Group] and t.Item = @RetId
	when not matched by target then insert
		(TenantId, [Root], [Parent], Item) values
		(@TenantId, s.ParentId, s.[Group], @RetId)
	when not matched by source and t.TenantId=@TenantId and t.Item = @RetId then delete;

	commit tran;

	exec cat.[Item.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @RetId;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Folder.GetPath]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Root bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with T(Id, Parent, [Level]) as (
		select cast(null as bigint), @Id, 0
		union all
		select tr.Id, tr.Parent, [Level] + 1 
			from cat.ItemTree tr inner join T on tr.Id = T.Parent and tr.TenantId = @TenantId
		where tr.Id <> @Root
	)
	select [Result!TResult!Array] = null, [Id] = Id from T where Id is not null order by [Level] desc;
end
go
------------------------------------------------
/*
create or alter procedure cat.[Item.Item.FindIndex]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Parent bigint,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc'
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Asc nvarchar(10), @Desc nvarchar(10), @RowCount int;

	set @Asc = N'asc'; set @Desc = N'desc';
	set @Dir = lower(isnull(@Dir, @Asc));
	set @Order = lower(@Order);

	with T(Id, RowNumber)
	as (
		select Id, [RowNumber] = row_number() over (
				order by 
					case when @Order=N'id'   and @Dir=@Asc  then i.Id end asc,
					case when @Order=N'id'   and @Dir=@Desc then i.Id end desc,
					case when @Order=N'name' and @Dir=@Asc  then i.[Name] end asc,
					case when @Order=N'name' and @Dir=@Desc then i.[Name] end desc,
					case when @Order=N'article' and @Dir=@Asc  then i.Article end asc,
					case when @Order=N'article' and @Dir=@Desc then i.Article end desc,
					case when @Order=N'memo' and @Dir=@Asc  then i.Memo end asc,
					case when @Order=N'memo' and @Dir=@Desc then i.Memo end desc
			)
			from cat.Items i inner join cat.ItemTreeItems iti on
			i.TenantId = iti.TenantId and i.Id = iti.Item
			where iti.Parent = @Parent and iti.TenantId = @TenantId
	)
	select [Result!TResult!Object] = null, T.Id, RowNo = T.RowNumber - 1 / *row_number is 1-based* /
	from T
	where T.Id = @Id;
end
*/
go
------------------------------------------------
create or alter procedure cat.[Item.Folder.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	if exists(select 1 from cat.ItemTree where TenantId=@TenantId and Parent = @Id and Void = 0) or
	   exists(select 1 from cat.ItemTree where TenantId=@TenantId and Parent = @Id and Void = 0)
		throw 60000, N'UI:@[Error.Delete.Folder]', 0;
	update cat.ItemTree set Void=1 where TenantId = @TenantId and Id = @Id;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Item.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	-- TODO: check if there are any references
	begin tran
	update cat.Items set Void=1 where TenantId = @TenantId and Id = @Id;
	/*
	delete from cat.ItemTreeItems where
		TenantId = @TenantId and Item = @Id;
	*/
	commit tran;
end
go
------------------------------------------------
create or alter procedure cat.[Item.Find.ArticleOrBarcode]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255) = null,
@PriceKind bigint = null,
@Date date = null,
@Wh bigint = null,
@Mode nchar(1) = N'A',
@Stock bit = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	declare  @item cat.[view_Items.TableType];
	insert into @item
	select top(1) *
	from cat.view_Items i
	where i.[!TenantId] = @TenantId and (@Stock is null or i.[!IsStock] = @Stock) and
		((@Mode = N'A' and i.Article = @Text) or (@Mode = 'B' and i.Barcode = @Text));

	if @PriceKind is not null
		update @item set Price = doc.fn_PriceGet(@TenantId, [Id!!Id], @PriceKind, @Date);
	if @Wh is not null
		update @item set Rem = doc.fn_getOneItemRem(@TenantId, [Id!!Id], [Role!TItemRole!RefId], @Date, @Wh);

	select [Item!TItem!Object] = null, *
	from @item;

	select [!TItemRole!Map] = null, * 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId and vir.[Id!!Id] in (select [Role!TItemRole!RefId] from @item);
end
go
------------------------------------------------
create or alter procedure cat.[Item.Find.Barcode]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare  @item cat.[view_Items.TableType];
	insert into @item
	select top(1) *
	from cat.view_Items i
	where i.[!TenantId] = @TenantId and i.Barcode = @Text;

	select [Item!TItem!Object] = null, *
	from @item;

	select [!TItemRole!Map] = null, * 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId and vir.[Id!!Id] in (select [Role!TItemRole!RefId] from @item);
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Rems.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Item!TItem!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Items where TenantId = @TenantId and Id = @Id;

	select [Rems!TRem!Array] = null, WhId =  Id, [WhName] = w.[Name]
	from cat.Warehouses w where TenantId = @TenantId
	order by Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Group.Elements.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	if exists(select 1 from doc.DocDetails where TenantId = @TenantId and Item = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	begin tran;
	delete from cat.ItemTreeElems where TenantId = @Id and Item = @Id;
	update cat.Items set Void = 1 where TenantId = @TenantId and Id=@Id;
	commit tran;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.FillList]
@TenantId int = 1,
@GroupId bigint = -1, -- GroupId
@IsStock nchar(1) = N'A',
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	declare @stock bit;

	set @stock = case @IsStock when N'T' then 1 when N'V' then 0 else null end;
	set @Dir = lower(@Dir);
	set @Order = lower(@Order);

	set @fr = N'%' + @Fragment + N'%';

	declare @items table(rowno int identity(1, 1), id bigint, unit bigint, [role] bigint, rowcnt int);
	--@Id = ite.Parent or 
	insert into @items(id, unit, [role], rowcnt)
	select i.Id, i.Unit, i.[Role],
		count(*) over()
	from cat.Items i
		left join cat.ItemTreeElems ite on i.TenantId = ite.TenantId and i.Id = ite.Item
		left join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
	where i.TenantId = @TenantId and i.Void = 0
		and (@GroupId = -1 or @GroupId = ite.Parent or (@GroupId < 0 and i.Id not in (
			select Item from cat.ItemTreeElems intbl where intbl.TenantId = @TenantId and intbl.[Root] = -@GroupId /*hack:negative*/
		)))
		and (@stock is null or isnull(ir.IsStock, 0) = @stock)
		and (@fr is null or i.[Name] like @fr or i.Memo like @fr or Article like @fr or ir.[Name] like @fr or Barcode like @fr)
	group by i.Id, i.Unit, i.[Name], i.Article, i.Barcode, i.Memo, i.[Role], ir.[Name]
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then i.[Name]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
				when N'role' then ir.[Name]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then i.[Name]
				when N'article' then i.[Article]
				when N'barcode' then i.Barcode
				when N'memo' then i.[Memo]
				when N'role' then ir.[Name]
			end
		end desc,
		i.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select id, rowno, unit, [role], rowcnt from @items;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Browse.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@IsStock nchar(1) = null,
@Wh bigint = null,
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @source table(rowno int, id bigint, unit bigint, [role] bigint, rowcnt int);

	insert into @source(id, rowno, unit, [role], rowcnt)
		exec cat.[Item.FillList] @TenantId = @TenantId, @PageSize = @PageSize, @Dir = @Dir, @Order = @Order, @Offset=@Offset,
			@IsStock = @IsStock, @Fragment = @Fragment;

	select [Items!TItem!Array] = null, 
			[Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], [!!RowCount] = s.rowcnt
	from cat.view_Items v
	inner join @source s on v.[Id!!Id] = s.id
	where v.[!TenantId] = @TenantId
	order by v.[!RowNo], v.[Id!!Id];

	-- all
	select [!TItemRole!Map] = null, vir.* 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId;

	-- system data
	select [!$System!] = null,
		[!Items!Offset] = @Offset, [!Items!PageSize] = @PageSize, 
		[!Items!SortOrder] = @Order, [!Items!SortDir] = @Dir,
		[!Items.Fragment!Filter] = @Fragment;
end
go
-------------------------------------------------
create or alter procedure cat.[Item.Browse.Price.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@IsStock nchar(1) = null,
@PriceKind bigint = null,
@Date datetime = null,
@CheckRems bit = 0,
@Wh bigint = null,
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	declare @source table(rowno int, id bigint, unit bigint, [role] bigint, rowcnt int);

	insert into @source(id, rowno, unit, [role], rowcnt)
		exec cat.[Item.FillList] @TenantId = @TenantId, @PageSize = @PageSize, @Dir = @Dir, @Order = @Order, @Offset=@Offset,
			@IsStock = @IsStock, @Fragment = @Fragment;

	declare @items cat.[view_Items.TableType];

	if @CheckRems = 1
	begin
		declare @itemstable a2sys.[Id.TableType];
		insert into @itemstable(Id) select id from @source;

		insert into @items([Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], Price, Rem, [!RowNo], [!!RowCount])
		select v.[Id!!Id], v.[Name!!Name], v.Article, v.Barcode, v.Memo, v.[Unit.Id!TUnit!Id], v.[Unit.Short!TUnit],
			isnull(t.[Role], v.[Role!TItemRole!RefId]), @TenantId, v.[!IsStock], v.Price, t.Rem, s.rowno, s.rowcnt
		from cat.view_Items v
			inner join @source s on v.[!TenantId] = @TenantId and s.id = v.[Id!!Id]
			left join doc.fn_getItemsRems(@CheckRems, @TenantId, @itemstable, @Date, @Wh) t
			on t.Item = v.[Id!!Id]
		where 
			v.[!TenantId] = @TenantId
	end
	else
	begin
		insert into @items ([Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], Price, Rem, [!RowNo], [!!RowCount])
		select v.[Id!!Id], v.[Name!!Name], v.Article, v.Barcode, v.Memo, v.[Unit.Id!TUnit!Id], v.[Unit.Short!TUnit],
			v.[Role!TItemRole!RefId], @TenantId, v.[!IsStock], 0, 0, [!RowNo] = s.rowno, [!!RowCount] = s.rowcnt
		from cat.view_Items v
			inner join @source s on v.[Id!!Id] = s.id
		where v.[!TenantId] = @TenantId
	end;

	-- update prices
	if @PriceKind is not null
	begin
		with TP as (
			select p.Item, [Date] = max(p.[Date])
			from doc.Prices p inner join @items t on p.TenantId = @TenantId and p.Item = t.[Id!!Id] and 
				p.[Date] <= @Date and p.PriceKind = @PriceKind
			group by p.Item, p.PriceKind
		),
		TX as (
			select p.Price, p.Item
			from doc.Prices p inner join TP on p.TenantId = @TenantId and p.Item = TP.Item 
				and p.PriceKind = @PriceKind and TP.[Date] = p.[Date]
		)
		update @items set Price = TX.Price 
		from @items t inner join TX on t.[Id!!Id] = TX.Item;
	end

	select [Items!TItem!Array] = null, v.*
	from @items v
	order by v.[!RowNo], v.[Id!!Id];

	-- all roles
	select [!TItemRole!Map] = null, vir.* 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId;

	select [PriceKind!TPriceKind!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Date] = @Date
	from cat.PriceKinds where TenantId = @TenantId and Id = @PriceKind;

	select [Params!TParam!Object] = null, CheckRems = @CheckRems, [Date] = @Date,
		[Warehouse.Id!TWarehouse!Id] = @Wh, [Warehouse.Name!TWarehouse!Name] = cat.fn_GetWarehouseName(@TenantId, @Wh);

	-- system data
	select [!$System!] = null,
		[!Items!Offset] = @Offset, [!Items!PageSize] = @PageSize, 
		[!Items!SortOrder] = @Order, [!Items!SortDir] = @Dir,
		[!Items.Fragment!Filter] = @Fragment;
end
go

-------------------------------------------------
create or alter procedure cat.[Item.Fetch.Price]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@IsStock nchar(1) = null,
@PriceKind bigint = null,
@Date datetime = null,
@CheckRems bit = 0,
@Wh bigint = null,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	declare @source table(rowno int, id bigint, unit bigint, [role] bigint, rowcnt int);

	insert into @source(id, rowno, unit, [role], rowcnt)
		exec cat.[Item.FillList] @TenantId = @TenantId, @PageSize = 100, @Dir = N'name', @Order = N'asc', @Offset=0,
			@IsStock = @IsStock, @Fragment = @Text;

	declare @items cat.[view_Items.TableType];

	if @CheckRems = 1
	begin
		declare @itemstable a2sys.[Id.TableType];
		insert into @itemstable(Id) select id from @source;

		insert into @items([Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], Price, Rem, [!RowNo], [!!RowCount])
		select v.[Id!!Id], v.[Name!!Name], v.Article, v.Barcode, v.Memo, v.[Unit.Id!TUnit!Id], v.[Unit.Short!TUnit],
			isnull(t.[Role], v.[Role!TItemRole!RefId]), @TenantId, v.[!IsStock], v.Price, t.Rem, s.rowno, s.rowcnt
		from cat.view_Items v
			inner join @source s on v.[!TenantId] = @TenantId and s.id = v.[Id!!Id]
			left join doc.fn_getItemsRems(@CheckRems, @TenantId, @itemstable, @Date, @Wh) t
			on t.Item = v.[Id!!Id]
		where 
			v.[!TenantId] = @TenantId;
	end
	else
	begin
		insert into @items ([Id!!Id], [Name!!Name], Article, Barcode, Memo, [Unit.Id!TUnit!Id], [Unit.Short!TUnit],
			[Role!TItemRole!RefId], [!TenantId], [!IsStock], Price, Rem, [!RowNo], [!!RowCount])
		select v.[Id!!Id], v.[Name!!Name], v.Article, v.Barcode, v.Memo, v.[Unit.Id!TUnit!Id], v.[Unit.Short!TUnit],
			v.[Role!TItemRole!RefId], @TenantId, v.[!IsStock], 0, 0, [!RowNo] = s.rowno, [!!RowCount] = s.rowcnt
		from cat.view_Items v
			inner join @source s on v.[Id!!Id] = s.id
		where v.[!TenantId] = @TenantId
	end;

	-- update prices
	if @PriceKind is not null
	begin
		with TP as (
			select p.Item, [Date] = max(p.[Date])
			from doc.Prices p inner join @items t on p.TenantId = @TenantId and p.Item = t.[Id!!Id] and 
				p.[Date] <= @Date and p.PriceKind = @PriceKind
			group by p.Item, p.PriceKind
		),
		TX as (
			select p.Price, p.Item
			from doc.Prices p inner join TP on p.TenantId = @TenantId and p.Item = TP.Item 
				and p.PriceKind = @PriceKind and TP.[Date] = p.[Date]
		)
		update @items set Price = TX.Price 
		from @items t inner join TX on t.[Id!!Id] = TX.Item;
	end

	select [Items!TItem!Array] = null, v.*
	from @items v
	order by v.[!RowNo], v.[Id!!Id];

	-- all roles
	select [!TItemRole!Map] = null, vir.* 
	from cat.view_ItemRoles vir 
	where vir.[!TenantId] = @TenantId;
end
go
