/* Brand */
------------------------------------------------
create or alter procedure cat.[Brand.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	with T(Id, [RowCount], RowNo) as (
	select b.Id, count(*) over (),
		RowNo = row_number() over (order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then b.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then b.[Id]
			end
		end desc,
		b.Id
		)
	from cat.Brands b
	where TenantId = @TenantId and Void = 0 and (@fr is null or b.[Name] like @fr or b.Memo like @fr))
	select [Brands!TBrand!Array] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo,
		[!!RowCount] = t.[RowCount]
	from cat.Brands b
		inner join T t on t.Id = b.Id and b.TenantId = @TenantId
	order by t.RowNo
	offset @Offset rows fetch next @PageSize rows only 
	option(recompile);

	select [!$System!] = null, [!Brands!Offset] = @Offset, [!Brands!PageSize] = @PageSize, 
		[!Brands!SortOrder] = @Order, [!Brands!SortDir] = @Dir,
		[!Brands.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Brand.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Brand!TBrand!Object] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo
	from cat.Brands b
	where b.TenantId = @TenantId and b.Id = @Id;
end
go
------------------------------------------------
drop procedure if exists cat.[Brand.Metadata];
drop procedure if exists cat.[Brand.Update];
drop type if exists cat.[Brand.TableType];
go
------------------------------------------------
create type cat.[Brand.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[Brand.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Brand cat.[Brand.TableType];
	select [Brand!Brand!Metadata] = null, * from @Brand;
end
go
---------------------------------------------
create or alter procedure cat.[Brand.Update]
@TenantId int = 1,
@UserId bigint,
@Brand cat.[Brand.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Brands as t
	using @Brand as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Brand.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Brand.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from cat.Items where TenantId = @TenantId and Brand = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.Brands set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[Brand.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Brands!TBrand!Array] = null, [Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo
	from cat.Brands b 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by b.[Name];
end
go
