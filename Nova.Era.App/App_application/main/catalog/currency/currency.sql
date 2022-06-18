/* CURRENCY */
------------------------------------------------
create or alter procedure cat.[Currency.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = -1,
@Order nvarchar(32) = N'number3',
@Dir nvarchar(5) = N'asc',
@Id bigint = null,
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + upper(@Fragment) + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	select [Currencies!TCurrency!Array] = null,
		[Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo, 
		c.Alpha3, c.Number3, c.Denom, c.[Symbol], c.Short
	from cat.Currencies c
	where TenantId = @TenantId
		and (@fr is null or c.Alpha3 like @fr or c.Number3 like @fr 
		or c.[Name] like @fr or c.Memo like @fr)
	order by
		case when @Dir = N'asc' then
			case @Order
				when N'alpha3' then c.[Alpha3]
				when N'number3' then c.[Number3]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'alpha3' then c.[Alpha3]
				when N'number3' then c.[Number3]
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc;

	select [!$System!] = null, [!Currencies!Offset] = @Offset, [!Currencies!PageSize] = @PageSize, 
		[!Currencies!SortOrder] = @Order, [!Currencies!SortDir] = @Dir,
		[!Currencies.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Currency.Catalog.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = -1,
@Order nvarchar(32) = N'number3',
@Dir nvarchar(5) = N'asc',
@Id bigint = null,
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	-- TenantId = 0 => From Catalog
	exec cat.[Currency.Index] @TenantId = 0, @UserId = @UserId, @Offset = @Offset,
		@PageSize = @PageSize, @Order=@Order, @Dir = @Dir, @Id = @Id, @Fragment = @Fragment;
end
go
------------------------------------------------
create or alter procedure cat.[Currency.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Currency!TCurrency!Object] = null,
		[Id!!Id] = c.Id, [NewId] = c.Id, [Name!!Name] = c.[Name], c.Memo, c.Alpha3, c.Number3, c.Denom, c.Symbol,
		c.Short
	from cat.Currencies c
	where c.TenantId = @TenantId and c.Id = @Id;
end
go
---------------------------------------------
drop procedure if exists cat.[Currency.Metadata];
drop procedure if exists cat.[Currency.Update];
drop type if exists cat.[Currency.TableType];
go
---------------------------------------------
create type cat.[Currency.TableType] as table
(
	Id bigint,
	[NewId] bigint,
	[Alpha3] nchar(3),
	[Number3] nchar(3),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Denom int,
	[Symbol] nvarchar(3),
	Short nvarchar(8)
)
go
---------------------------------------------
create or alter procedure cat.[Currency.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Currency cat.[Currency.TableType];
	select [Currency!Currency!Metadata] = null, * from @Currency;
end
go
---------------------------------------------
create or alter procedure cat.[Currency.Update]
@TenantId int = 1,
@UserId bigint,
@Currency cat.[Currency.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Currencies as t
	using @Currency as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[Alpha3] = s.[Alpha3],
		t.[Number3] = s.Number3,
		t.[Symbol] = s.[Symbol],
		t.[Denom] = s.[Denom],
		t.[Short] = s.[Short]
	when not matched by target then insert
		(TenantId, Id, [Name], Memo, Alpha3, Number3, [Symbol], [Denom], [Short]) values
		(@TenantId, s.[NewId], s.[Name], s.Memo, s.Alpha3, s.Number3, s.[Symbol], s.Denom, s.[Short])
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Currency.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Currency.CheckDuplicate]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Number3 nvarchar(3)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @valid bit = 1;

	if exists(select 1 from cat.Currencies where TenantId = @TenantId and Number3 = @Number3 and Id <> @Id)
		set @valid = 0;

	select [Result!TResult!Object] = null, [Value] = @valid;
end
go
---------------------------------------------
create or alter procedure cat.[Currency.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Currencies set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go
---------------------------------------------
create or alter procedure cat.[Currency.AddFromCatalog]
@TenantId int = 1,
@UserId bigint,
@Ids nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	merge cat.Currencies as t
	using (
		select cs.Id, cs.Alpha3, cs.Number3, cs.[Symbol], cs.Denom, cs.[Name] from cat.Currencies cs 
			inner join string_split(@Ids, N',') t on cs.TenantId = 0 and cs.Id = t.[value]) as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set 
		Alpha3 = s.Alpha3,
		Number3 = s.Number3,
		[Symbol] = s.[Symbol],
		Denom = s.Denom,
		[Name] = s.[Name],
		Void = 0
	when not matched by target then insert
		(TenantId, Id, Alpha3, Number3, [Symbol], Denom, [Name]) values
		(@TenantId, s.Id, s.Alpha3, s.Number3, s.[Symbol], s.Denom, s.[Name]);
end
go
