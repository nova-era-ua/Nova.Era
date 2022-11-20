/* ITEM OPTIONS */
------------------------------------------------
create or alter procedure cat.[ItemOption.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Options!TOption!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Memo],
		[Items!TOptionValue!Array] = null
	from cat.ItemOptions 
	where TenantId = @TenantId and Void = 0;

	select [!TOptionValue!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name],
		[!TOption.Items!ParentId] = [Option]
	from cat.ItemOptionValues
	where TenantId = @TenantId and Void = 0;
end
go
-------------------------------------------------
create or alter procedure cat.[ItemOption.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Option!TOption!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Memo],
		[Items!TOptionValue!Array] = null
	from cat.ItemOptions 
	where TenantId = @TenantId and Id = @Id;

	select [!TOptionValue!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[!TOption.Items!ParentId] = [Option]
	from cat.ItemOptionValues
	where TenantId = @TenantId and [Option] = @Id and Void = 0
end
go
------------------------------------------------
drop procedure if exists cat.[ItemOption.Metadata];
drop procedure if exists cat.[ItemOption.Update];
drop type if exists cat.[ItemOption.TableType];
drop type if exists cat.[ItemOptionValue.TableType];
go
------------------------------------------------
create type cat.[ItemOption.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
);
go
-------------------------------------------------
create type cat.[ItemOptionValue.TableType]
as table (
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
);
go
-------------------------------------------------
create or alter procedure cat.[ItemOption.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Option cat.[ItemOption.TableType];
	declare @Values cat.[ItemOptionValue.TableType];

	select [Option!Option!Metadata] = null, * from @Option;
	select [Values!Option.Items!Metadata] = null, * from @Values;
end
go
-------------------------------------------------
create or alter procedure cat.[ItemOption.Update]
@TenantId int = 1,
@UserId bigint,
@Option [ItemOption.TableType] readonly,
@Values cat.[ItemOptionValue.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output table(op sysname, id bigint);

	merge cat.ItemOptions as t
	using @Option as s
	on (t.Id = s.Id and t.TenantId = @TenantId)
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Memo] = s.Memo
	when not matched by target then 
		insert (TenantId, [Name], Memo)
		values (@TenantId, s.[Name], s.Memo)
	output 
		$action op, inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	with TV as (
		select * from cat.ItemOptionValues where TenantId = @TenantId and [Option] = @RetId and Void = 0
	)
	merge TV as t
	using @Values as s
	on (t.Id = s.Id)
	when matched then update set 
		t.[Name] = s.[Name],
		t.[Memo] = s.Memo,
		t.Void = 0
	when not matched by target then 
		insert (TenantId, [Option], [Name], Memo)
		values (@TenantId, @RetId, s.[Name], s.Memo)
	when not matched by source then update set
		t.Void = 1;

	exec cat.[ItemOption.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @RetId;
end
go
-------------------------------------------------
create or alter procedure cat.[ItemOption.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	begin tran;
	update cat.ItemOptions set Void = 1 where TenantId = @TenantId and Id = @Id;
	commit tran;
end
go