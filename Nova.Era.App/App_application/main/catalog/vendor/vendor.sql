/* Vendor */
drop procedure if exists cat.[Vendor.Metadata];
drop procedure if exists cat.[Vendor.Update];
drop type if exists cat.[Vendor.TableType];
go
------------------------------------------------
create type cat.[Vendor.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Vendor.Index]
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
	select v.Id, count(*) over (),
		RowNo = row_number() over (order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then v.[Name]
				when N'memo' then v.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then v.[Name]
				when N'memo' then v.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then v.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then v.[Id]
			end
		end desc,
		v.Id
		)
	from cat.Vendors v
	where TenantId = @TenantId and Void = 0 and (@fr is null or v.[Name] like @fr or v.Memo like @fr))
	select [Vendors!TVendor!Array] = null,
		[Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Memo,
		[!!RowCount] = t.[RowCount]
	from cat.Vendors v
		inner join T t on t.Id = v.Id
	order by t.RowNo
	offset @Offset rows fetch next @PageSize rows only 
	option(recompile);

	select [!$System!] = null, [!Vendors!Offset] = @Offset, [!Vendors!PageSize] = @PageSize, 
		[!Vendors!SortOrder] = @Order, [!Vendors!SortDir] = @Dir,
		[!Vendors.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Vendor.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Vendor!TVendor!Object] = null,
		[Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Memo
	from cat.Vendors v
	where v.TenantId = @TenantId and v.Id = @Id;
end
go
---------------------------------------------
create or alter procedure cat.[Vendor.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Vendor cat.[Vendor.TableType];
	select [Vendor!Vendor!Metadata] = null, * from @Vendor;
end
go
---------------------------------------------
create or alter procedure cat.[Vendor.Update]
@TenantId int = 1,
@UserId bigint,
@Vendor cat.[Vendor.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Vendors as t
	using @Vendor as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Vendor.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Vendor.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from cat.Items where TenantId = @TenantId and Vendor = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.Vendors set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[Vendor.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Vendors!TVendor!Array] = null, [Id!!Id] = v.Id, [Name!!Name] = v.[Name], v.Memo
	from cat.Vendors v 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by v.[Name];
end
go
