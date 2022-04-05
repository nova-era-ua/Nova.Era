/* BANK */
------------------------------------------------
create or alter procedure cat.[Bank.Index]
@TenantId int = 1,
@UserId bigint,
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
	set @fr = N'%' + upper(@Fragment) + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	with T(Id, [RowCount], RowNo) as (
	select b.Id, count(*) over (),
		RowNo = row_number() over (order by 
		case when @Dir = N'asc' then
			case @Order
				when N'code' then b.[Code]
				when N'bankcode' then b.[BankCode]
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'code' then b.[Code]
				when N'bankcode' then b.[BankCode]
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
	from cat.Banks b
	where TenantId = @TenantId and (@fr is null or b.BankCode like @fr or b.Code like @fr 
		or b.[Name] like @fr or b.FullName like @fr or b.Memo like @fr)
	)
	select [Banks!TBank!Array] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.FullName, 
		b.Code, b.BankCode, b.Memo,
		[!!RowCount] = t.[RowCount]
	from cat.Banks b
	inner join T t on t.Id = b.Id
	order by t.RowNo
	offset @Offset rows fetch next @PageSize rows only;

	select [!$System!] = null, [!Banks!Offset] = @Offset, [!Banks!PageSize] = @PageSize, 
		[!Banks!SortOrder] = @Order, [!Banks!SortDir] = @Dir,
		[!Banks.Fragment!Filter] = @Fragment
end
go
------------------------------------------------
create or alter procedure cat.[Bank.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Bank!TBank!Object] = null,
		[Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.Memo, b.[Code], b.FullName, b.BankCode
	from cat.Banks b
	where TenantId = @TenantId and b.Id = @Id;
end
go
---------------------------------------------
drop procedure if exists cat.[Bank.Upload.Metadata];
drop procedure if exists cat.[Bank.Upload.Update];
drop procedure if exists cat.[Bank.Metadata];
drop procedure if exists cat.[Bank.Update];
drop type if exists cat.[Bank.Upload.TableType];
drop type if exists cat.[Bank.TableType];
go
---------------------------------------------
create type cat.[Bank.Upload.TableType] as table
(
	Id bigint,
	[GLMFO] nvarchar(255),
	[SHORTNAME] nvarchar(255),
	[FULLNAME] nvarchar(255),
	[KOD_EDRPOU] nvarchar(50)
)
go
------------------------------------------------
create type cat.[Bank.TableType] as table
(
	Id bigint,
	[Code] nvarchar(16),
	[BankCode] nvarchar(16),
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[Bank.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Bank cat.[Bank.TableType];
	select [Bank!Bank!Metadata] = null, * from @Bank;
end
go
---------------------------------------------
create or alter procedure cat.[Bank.Update]
@TenantId int = 1,
@UserId bigint,
@Bank cat.[Bank.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.Banks as t
	using @Bank as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[BankCode] = s.[BankCode],
		t.[FullName] = s.[FullName], 
		t.[Code] = s.[Code]
	when not matched by target then insert
		(TenantId, [Name], Memo, BankCode, FullName, Code) values
		(@TenantId, [Name], Memo, BankCode, FullName, Code)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Bank.Load] @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[Bank.Upload.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Banks cat.[Bank.Upload.TableType];
	select [Banks!Banks!Metadata] = null, * from @Banks;
end
go

---------------------------------------------
create or alter procedure cat.[Bank.Upload.Update]
@TenantId int = 1,
@UserId bigint,
@Banks cat.[Bank.Upload.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	merge cat.Banks as t
	using @Banks as s
	on t.TenantId = @TenantId and t.BankCode = s.[GLMFO]
	when matched then update set
		t.BankCode = s.[GLMFO],
		t.[Name] =  s.[SHORTNAME],
		t.[Code] = s.KOD_EDRPOU,
		t.[FullName] = s.FULLNAME,
		t.Void = 0
	when not matched by target then insert
		(TenantId, BankCode, [Name], [Code], [FullName]) values
		(@TenantId, s.[GLMFO], [SHORTNAME], KOD_EDRPOU, FULLNAME);

	select [Result!TResult!Object] = null, Loaded = (select count(*) from @Banks);
end
go
------------------------------------------------
create or alter procedure cat.[Bank.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Banks set Void = 1 where TenantId = @TenantId and Id = @Id;
end
go


