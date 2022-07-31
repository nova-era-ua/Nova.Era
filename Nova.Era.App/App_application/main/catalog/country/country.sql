/* Country */
------------------------------------------------
create or alter procedure cat.[Country.Index]
@TenantId int = 1,
@UserId bigint,
@Id nchar(3) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Countries!TCountry!Array] = null, [Id!!Id] = Code, [Name!!Name] = [Name], Alpha2, Alpha3, Memo
	from cat.Countries c
	where c.TenantId = @TenantId and c.Void = 0;
end
go
------------------------------------------------
create or alter procedure cat.[Country.Load]
@TenantId int = 1,
@UserId bigint,
@Id nchar(3) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Country!TCountry!Object] = null,
		[Id!!Id] = c.Code, [Name!!Name] = c.[Name], c.Memo, c.Alpha2, c.Alpha3
	from cat.Countries c
	where c.TenantId = @TenantId and c.Code = @Id;
end
go
------------------------------------------------
drop procedure if exists cat.[Country.Metadata];
drop procedure if exists cat.[Country.Update];
drop type if exists cat.[Country.TableType];
go
------------------------------------------------
create type cat.[Country.TableType] as table
(
	Id nchar(3),
	[Alpha2] nchar(2),
	[Alpha3] nchar(3),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[Country.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Country cat.[Country.TableType];
	select [Country!Country!Metadata] = null, * from @Country;
end
go
---------------------------------------------
create or alter procedure cat.[Country.Update]
@TenantId int = 1,
@UserId bigint,
@Country cat.[Country.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id nchar(3));
	declare @id bigint;

	merge cat.Countries as t
	using @Country as s on (t.TenantId = @TenantId and t.Code = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo], 
		t.[Alpha3] = s.[Alpha3],
		t.[Alpha2] = s.[Alpha2]
	when not matched by target then insert
		(TenantId, Code, [Name], Memo, Alpha2, Alpha3) values
		(@TenantId, Id, [Name], Memo, Alpha2, Alpha3)
	output $action, inserted.Code into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[Country.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
/*
---------------------------------------------
create or alter procedure cat.[Country.AddFromCatalog]
@TenantId int = 1,
@UserId bigint,
@Ids nvarchar(max)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	merge cat.Countrys as t
	using (
		select u.Id, u.Short, u.CodeUA, u.[Name] 
		from cat.Countrys u
			inner join string_split(@Ids, N',') t on u.TenantId = 0 and u.Id = t.[value]) as s
	on t.TenantId = @TenantId and t.CodeUA = s.CodeUA
	when matched then update set 
		Short = s.Short,
		[Name] = s.[Name],
		Void = 0
	when not matched by target then insert
		(TenantId, Short, CodeUA, [Name]) values
		(@TenantId, s.Short, s.CodeUA, s.[Name]);
end
go
*/
---------------------------------------------
create or alter procedure cat.[Country.Delete]
@TenantId int = 1,
@UserId bigint,
@Id nchar(3)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if exists(select 1 from cat.Items where TenantId = @TenantId and Country = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update cat.Countries set Void = 1 where TenantId = @TenantId and Code=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[Country.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Countries!TCountry!Array] = null, [Id!!Id] = c.Code, [Name!!Name] = c.[Name], 
		c.[Alpha2], c.[Alpha3]
	from cat.Countries c 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or [Alpha3] like @fr or [Alpha2] like @fr)
	order by c.[Code];
end
go
