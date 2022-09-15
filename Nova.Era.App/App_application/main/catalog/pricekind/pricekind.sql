/* PRICEKINDS */
------------------------------------------------
drop procedure if exists cat.[PriceKind.Metadata];
drop procedure if exists cat.[PriceKind.Update];
drop type if exists cat.[PriceKind.TableType];
go
------------------------------------------------
create or alter procedure cat.[PriceKind.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PriceKinds!TPriceKind!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.PriceKinds pk
	where TenantId = @TenantId and Void = 0
	order by pk.Id;
end
go
------------------------------------------------
create or alter procedure cat.[PriceKind.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PriceKind!TPriceKind!Object] = null, [Id!!Id] = pk.Id, [Name!!Name] = [Name], [Memo]
	from cat.PriceKinds pk
	where TenantId = @TenantId and Id = @Id;
end
go
---------------------------------------------
create type cat.[PriceKind.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
---------------------------------------------
create or alter procedure cat.[PriceKind.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @PriceKind cat.[PriceKind.TableType];
	select [PriceKind!PriceKind!Metadata] = null, * from @PriceKind;
end
go
---------------------------------------------
create or alter procedure cat.[PriceKind.Update]
@TenantId int = 1,
@UserId bigint,
@PriceKind cat.[PriceKind.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.PriceKinds as t
	using @PriceKind as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, [Name], Memo) values
		(@TenantId, [Name], Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[PriceKind.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[PriceKind.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.PriceKinds set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

------------------------------------------------
create or alter procedure cat.[PriceKind.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [PriceKinds!TPriceKind!Array] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name], pk.Memo
	from cat.PriceKinds pk 
	where TenantId = @TenantId and Void = 0 and ([Name] like @fr or Memo like @fr)
	order by pk.[Name];
end
go

