/* Project */
drop procedure if exists cat.[Project.Metadata];
drop procedure if exists cat.[Project.Update];
drop type if exists cat.[Project.TableType];
go
------------------------------------------------
create type cat.[Project.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure cat.[Project.Index]
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
	select p.Id, count(*) over (),
		RowNo = row_number() over (order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then p.[Name]
				when N'memo' then p.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then p.[Name]
				when N'memo' then p.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then p.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then p.[Id]
			end
		end desc,
		p.Id
		)
	from cat.Projects p
	where TenantId = @TenantId and Void = 0 and (@fr is null or p.[Name] like @fr or p.Memo like @fr))
	select [Projects!TProject!Array] = null,
		[Id!!Id] = p.Id, [Name!!Name] = p.[Name], p.Memo,
		[!!RowCount] = t.[RowCount]
	from cat.Projects p
		inner join T t on t.Id = p.Id and p.TenantId = @TenantId
	order by t.RowNo
	offset @Offset rows fetch next @PageSize rows only 
	option(recompile);

	select [!$System!] = null, [!Projects!Offset] = @Offset, [!Projects!PageSize] = @PageSize, 
		[!Projects!SortOrder] = @Order, [!Projects!SortDir] = @Dir,
		[!Projects.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Project.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Project!TProject!Object] = null,
		[Id!!Id] = p.Id, [Name!!Name] = p.[Name], p.Memo
	from cat.Projects p
	where p.TenantId = @TenantId and p.Id = @Id;
end
go
---------------------------------------------
create or alter procedure cat.[Project.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Project cat.[Project.TableType];
	select [Project!Project!Metadata] = null, * from @Project;
end
go
---------------------------------------------
create or alter procedure cat.[Project.Update]
@TenantId int = 1,
@UserId bigint,
@Project cat.[Project.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Projects as t
	using @Project as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Project.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Project.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Projects set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[Project.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Projects!TProject!Array] = null, [Id!!Id] = p.Id, [Name!!Name] = p.[Name], p.Memo
	from cat.Projects p 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by p.[Name];
end
go
