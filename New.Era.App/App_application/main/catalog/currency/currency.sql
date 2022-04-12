/* CURRENCY */
drop procedure if exists cat.[Currency.Metadata];
drop procedure if exists cat.[Currency.Update];
drop type if exists cat.[Currency.TableType];
go
create type cat.[Currency.TableType] as table
(
	Id bigint,
	[Alpha3] nchar(3),
	[Number3] nchar(3),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Denom int,
	[Char] nchar(1)
)
go
------------------------------------------------
create or alter procedure cat.[Currency.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Currencies!TCurrency!Array] = null,
		[Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo, c.Alpha3, c.Number3, c.Denom, c.[Char]
	from cat.Currencies c
	where TenantId = @TenantId
	order by c.Id;
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
		[Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo, c.Alpha3, c.Number3, c.Denom, c.[Char]
	from cat.Currencies c
	where c.TenantId = @TenantId and c.Id = @Id;
end
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
		t.[Number3] = s.Number3
	when not matched by target then insert
		(TenantId, Id, [Name], Memo, Alpha3, Number3, [Char]) values
		(@TenantId, s.Id, s.[Name], s.Memo, s.Alpha3, s.Number3, s.[Char])
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Currency.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
