/* ITEM ROLE */
drop procedure if exists cat.[ItemRole.Metadata];
drop procedure if exists cat.[ItemRole.Update];
drop type if exists cat.[ItemRole.TableType];
drop type if exists cat.[ItemRoleAccount.TableType];
go
------------------------------------------------
create type cat.[ItemRole.TableType] as table
(
	Id bigint,
	[Kind] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Color] nvarchar(32),
	HasPrice bit,
	IsStock bit,
	CostItem bigint
)
go
------------------------------------------------
create type cat.[ItemRoleAccount.TableType] as table
(
	Id bigint,
	[Plan] bigint,
	Account bigint,
	AccKind bigint
)
go
------------------------------------------------
create or alter procedure cat.[ItemRole.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [ItemRoles!TItemRole!Array] = null,
		[Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Kind, ir.Memo, ir.Color, ir.HasPrice, ir.IsStock
	from cat.ItemRoles ir
	where ir.TenantId = @TenantId and ir.Void = 0
	order by ir.Id;
end
go
------------------------------------------------
create or alter procedure cat.[ItemRole.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [ItemRole!TItemRole!Object] = null,
		[Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.Memo, ir.Kind, ir.Color, ir.HasPrice, ir.IsStock,
		[CostItem!TCostItem!RefId] = ir.CostItem,
		[Accounts!TRoleAccount!Array] = null
	from cat.ItemRoles ir
	where ir.TenantId = @TenantId and ir.Id = @Id;

	select [!TRoleAccount!Array] = null, [Id!!Id] = ira.Id, [Plan!TAccount!RefId] = ira.[Plan],
		[Account!TAccount!RefId] = ira.Account, [AccKind!TAccKind!RefId] = ira.AccKind,
		[!TItemRole.Accounts!ParentId] = ira.[Role]
	from cat.ItemRoleAccounts ira
	where ira.TenantId = @TenantId and ira.[Role] = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = a.Id, [Code] = a.Code, [Name!!Name] = a.[Name]
	from acc.Accounts a
		inner join cat.ItemRoleAccounts ira on a.TenantId = ira.TenantId and a.Id in (ira.[Plan], ira.[Account])
	where ira.TenantId = @TenantId and ira.[Role] = @Id
	group by a.Id, a.Code, a.[Name];

	select [!TCostItem!Map] = null, [Id!!Id] = ci.Id, [Name!!Name] = ci.[Name]
	from cat.CostItems ci
		inner join cat.ItemRoles ir on ci.TenantId = ir.TenantId and ir.CostItem = ci.Id
	where ci.TenantId = @TenantId and ir.Id = @Id;

	select [AccKinds!TAccKind!Array] = null, [Id!!Id] = ak.Id, [Name!!Name] = ak.[Name]
	from acc.AccKinds ak
	where ak.TenantId = @TenantId and ak.Void = 0;
end
go
---------------------------------------------
create or alter procedure cat.[ItemRole.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Role cat.[ItemRole.TableType];
	declare @Accounts cat.[ItemRoleAccount.TableType];
	select [ItemRole!ItemRole!Metadata] = null, * from @Role;
	select [Accounts!ItemRole.Accounts!Metadata] = null, * from @Accounts;
end
go
---------------------------------------------
create or alter procedure cat.[ItemRole.Update]
@TenantId int = 1,
@UserId bigint,
@ItemRole cat.[ItemRole.TableType] readonly,
@Accounts cat.[ItemRoleAccount.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.ItemRoles as t
	using @ItemRole as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Kind] = s.[Kind],
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Color = s.Color,
		t.HasPrice = s.HasPrice,
		t.IsStock = s.IsStock,
		t.CostItem = s.CostItem
	when not matched by target then insert
		(TenantId, Kind, [Name], Memo, Color, HasPrice, IsStock, CostItem) values
		(@TenantId, Kind, [Name], Memo, Color, HasPrice, IsStock, CostItem)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	
	merge cat.ItemRoleAccounts as t
	using @Accounts as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Plan] = s.[Plan],
		t.Account = s.Account,
		t.AccKind = s.AccKind
	when not matched by target then insert
		(TenantId, [Role], [Plan], Account, AccKind) values
		(@TenantId, @id, s.[Plan], s.Account, s.AccKind)
	when not matched by source and t.TenantId = @TenantId and t.[Role] = @id then delete;

	exec cat.[ItemRole.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure cat.[ItemRole.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.ItemRoles set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

