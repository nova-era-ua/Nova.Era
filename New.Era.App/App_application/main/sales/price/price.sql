-- SALES.PRICE
-------------------------------------------------
create or alter procedure doc.[Price.Index]
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
		select Id = -@Group, 2, [Name] = N'@[WithoutGroup]', 0, Icon=N'ban'
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
		[Prices!TPriceItem!LazyArray] = null
	from T
	order by _order, [Id];

	select [Checked!TChecked!Object] = null, 
		[PriceKind1!TPriceKind!RefId] = [1], 
		[PriceKind2!TPriceKind!RefId] = [2], 
		[PriceKind3!TPriceKind!RefId] = [3] 
	from (
		select top(3) Id, RowNo = row_number() over(order by Id) from cat.PriceKinds
		where TenantId = @TenantId and Void = 0
	) t pivot (sum(Id) for RowNo in ([1], [2], [3])) pvt;

	select [PriceKinds!TPriceKind!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.PriceKinds where TenantId = @TenantId and Void = 0
	order by Id;

	-- Prices definition
	select [!TPriceItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
		[Values!TPriceValue!Array] = null
	from cat.Items i
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	where 0 <> 0;

	select [!TPriceValue] = null, p.Price, p.PriceKind, [Date] = p.[Date], [!TPriceItem.Values!ParentId] = p.Item
	from doc.Prices p where 0 <> 0;

	-- filters
	select [Hierarchies!THie!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.ItemTree where TenantId = @TenantId and Parent = 0 and Id <> Parent and Id <> 0;

	select [!$System!] = null,
		[!Hierarchies.Group!Filter] = @Group
end
go
-------------------------------------------------
create or alter procedure doc.[Price.Expand]
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
create or alter procedure doc.[Price.Prices]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null, -- GroupId
@Offset int = 0, 
@PageSize int = 20,
@Order nvarchar(255) = N'name',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null,
@Date date = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';

	declare @items table(rowno int identity(1, 1), id bigint, unit bigint, rowcnt int);
	--@Id = ite.Parent or 
	insert into @items(id, unit, rowcnt)
	select i.Id, i.Unit,
		count(*) over()
	from cat.Items i
		inner join cat.ItemRoles ir on i.TenantId = ir.TenantId and i.[Role] = ir.Id
		left join cat.ItemTreeElems ite on i.TenantId = ite.TenantId and i.Id = ite.Item
	where i.TenantId = @TenantId and i.Void = 0 and ir.HasPrice = 1
		and (@Id = -1 or @Id = ite.Parent or (@Id < 0 and i.Id not in (
			select Item from cat.ItemTreeElems intbl where intbl.TenantId = @TenantId and intbl.[Root] = -@Id /*hack:negative*/
		)))
		and (@fr is null or i.[Name] like @fr or i.Memo like @fr or Article like @fr)
	group by i.Id, i.Unit, i.[Name], i.Article, i.Memo, i.[Role]
	order by i.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Prices!TPriceItem!Array] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], i.Article,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit] = u.Short,
		[Values!TPriceValue!Array] = null,
		[!!RowCount]  = t.rowcnt
	from @items t inner join cat.Items i on i.TenantId = @TenantId and i.Id = t.id
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	order by t.rowno;

	with TP as (
		select p.Item, p.PriceKind, [Date] = max(p.[Date])
		from doc.Prices p inner join @items t on p.TenantId = @TenantId and p.Item = t.id and 
			p.[Date] <= @Date
		group by p.Item, p.PriceKind
	)
	select [!TPriceValue!Array] = null, p.Price, p.PriceKind, [Date] = TP.[Date], [!TPriceItem.Values!ParentId] = TP.Item
	from doc.Prices p inner join TP on p.TenantId = @TenantId and p.Item = TP.Item 
		and p.PriceKind = TP.PriceKind and TP.[Date] = p.[Date];

	-- system data
	select [!$System!] = null,
		[!Prices!Offset] = @Offset, [!Prices!PageSize] = @PageSize, 
		[!Prices!SortOrder] = @Order, [!Prices!SortDir] = @Dir,
		[!Prices.Fragment!Filter] = @Fragment, [!Prices.Date!Filter] = @Date;
end
go
-------------------------------------------------
create or alter procedure doc.[Price.Set]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@PriceKind bigint,
@Date date,
@Value float
as
begin
	set nocount on;
	set transaction isolation level read committed;

	--TODO: Price.Currency

	merge doc.Prices as t
	using (select Item = @Id, PriceKind = @PriceKind, [Date] = @Date, [Price] = @Value) as s
	on t.TenantId = @TenantId and t.Item = s.Item and t.PriceKind = s.PriceKind and t.[Date] = s.[Date]
	when matched then update set
		t.Price = s.[Price]
	when not matched by target then insert
		(TenantId, Item, PriceKind, [Date], Price, Currency) values
		(@TenantId, Item, PriceKind, [Date], Price, 980);
end
go

-------------------------------------------------
create or alter procedure doc.[Price.Items.Get]
@TenantId int = 1,
@UserId bigint,
@Items nvarchar(1024),
@PriceKind bigint,
@Date date
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	with TP as (
		select p.Item, [Date] = max(p.[Date])
		from doc.Prices p inner join string_split(@Items, N',') t on p.TenantId = @TenantId and p.Item = t.[value] 
			and p.[Date] <= @Date and p.PriceKind = @PriceKind
		group by p.Item
	)
	select [Prices!TPrice!Array] = null, p.Item, p.Price
	from doc.Prices p inner join TP on p.TenantId = @TenantId and p.Item = TP.Item 
		and p.PriceKind = @PriceKind and TP.[Date] = p.[Date];
end
go
-------------------------------------------------
create or alter function doc.fn_PriceGet(@TenantId int, @Item bigint, @PriceKind bigint, @Date date)
returns float
as
begin
	declare @val float;
	select @val = p.Price 
	from doc.Prices p where p.[Date] <= @Date and PriceKind = @PriceKind and p.Item = @Item
	return @val;
end
go
