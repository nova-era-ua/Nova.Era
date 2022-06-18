-- reports
-------------------------------------------------
create or alter procedure rep.[Report.Index]
@TenantId int = 1,
@UserId bigint,
@Menu nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Reports!TReport!Array] = null, [Id!!Id] = r.Id, [Name!!Name] = [Name], Memo,
		Menu, [File!TRepFile!RefId] = [File], r.Account
	from rep.Reports r
	where TenantId = @TenantId and [Menu] = @Menu;

	select [!TRepFile!Map] = null, [Id!!Id] = rf.Id, [Url]
	from rep.RepFiles rf inner join rep.Reports r on r.TenantId = rf.TenantId and r.[File] = rf.[Id]
	where r.TenantId = @TenantId and r.Menu = @Menu;

	select [Params!TParam!Object] = null, Menu = @Menu;
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Menu nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = [Name], Memo,
		[Menu], [File!TRepFile!RefId] = [File], [Account!TAccount!RefId] = Account,
		[Type!TRepType!RefId] = [Type]
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = a.Id, [Code], [Name!!Name] = a.[Name],
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash
	from acc.Accounts a inner join rep.Reports r on a.TenantId = r.TenantId and a.Id = r.Account
	where r.TenantId = @TenantId and r.Id = @Id;

	select [RepTypes!TRepType!Array] = null, [Id!!Id] = rt.Id, [Name!!Name] = rt.[Name],
		UseAccount, [UsePlan], [Files!TRepFile!Array] = null
	from rep.RepTypes rt where TenantId = @TenantId order by rt.[Order];

	select [!TRepFile!Array] = null, [Id!!Id] = rf.Id, [Name!!Name] = rf.[Name],
		[!TRepType.Files!ParentId] = [Type], [Url]
	from rep.RepFiles rf where TenantId = @TenantId order by rf.[Order]

	select [Params!TParam!Object] = null, Menu = @Menu;
end
go
-------------------------------------------------
drop procedure if exists rep.[Report.Metadata];
drop procedure if exists rep.[Report.Update];
drop type if exists rep.[Report.TableType];
go
-------------------------------------------------
create type rep.[Report.TableType] as table (
	Id bigint,
	[Menu] nvarchar(32),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Type] nvarchar(16),
	[File] nvarchar(16),
	Account bigint
);
go
-------------------------------------------------
create or alter procedure rep.[Report.Metadata]
as
begin
	set nocount on;
	declare @Report rep.[Report.TableType];
	select [Report!Report!Metadata] = null, * from @Report;
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Update]
@TenantId int = 1,
@UserId bigint,
@Report rep.[Report.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge rep.Reports as t
	using @Report as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Type] = s.[Type],
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Account = s.Account,
		t.[File] = s.[File]
	when not matched by target then insert
		(TenantId, [Type], Menu, [Name], Memo, Account, [File]) values
		(@TenantId, s.[Type], s.Menu, [Name], Memo, Account, [File])
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec rep.[Report.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Menu nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	delete from rep.Reports where TenantId = @TenantId and Id = @Id;
end
go