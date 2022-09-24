------------------------------------------------
create or alter procedure app.[Application.Delete]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from ui.OpMenuLinks where TenantId = @TenantId;
	delete from doc.OpPrintForms where TenantId = @TenantId;
	delete from doc.OperationLinks where TenantId = @TenantId;
	delete from doc.OpTrans where TenantId = @TenantId;
	delete from doc.AutonumValues where TenantId = @TenantId;
	delete from doc.Autonums where TenantId = @TenantId;
	delete from doc.Operations where TenantId = @TenantId;
	delete from cat.ItemRoleAccounts where TenantId = @TenantId;
end
go
------------------------------------------------
create or alter procedure app.[Application.Export.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Application!TApp!Object] = null, [!!Id] = 1,
		[AccKinds!AccKind!Array] = null, [Accounts!TAccount!Array] = null,
		[ItemRoles!TItemRole!Array] = null, [Operations!TOperation!Array] = null,
		[CostItems!TCostItem!Array] = null, [Autonums!TAutonum!Array] = null;

	select [!TAccKind!Array] = null, [Uid!!Id] = Uid, [Name], Memo,
		[!TApp.AccKinds!ParentId] = 1
	from acc.AccKinds where TenantId = @TenantId and Void = 0;

	with T(Id, Parent, [Plan], [Level])
	as (
		select a.Id, Parent, a.[Plan], 0 from
			acc.Accounts a where TenantId=@TenantId and a.Parent is null and a.[Plan] is null and Void=0
		union all 
		select a.Id, a.Parent, a.[Plan], T.[Level] + 1 
		from acc.Accounts a
			inner join T on T.Id = a.Parent and a.TenantId = @TenantId and a.Void = 0
		where a.TenantId = @TenantId
	)
	select [!TAccount!Array] = null, [Uid!!Id] = a.[Uid], [ParentAcc] = p.[Uid], [Plan] = pl.[Uid], T.[Level],
		a.[Name], a.Code, a.Memo,
		a.IsFolder, a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash, a.IsContract, a.IsRespCenter, a.IsCostItem,		
		[!TApp.Accounts!ParentId] = 1
	from acc.Accounts a inner join T on a.TenantId = @TenantId and a.Id = T.Id
		left join acc.Accounts p on a.TenantId = p.TenantId and p.Id = T.Parent
		left join acc.Accounts pl on a.TenantId = p.TenantId and pl.Id = T.[Plan]
	order by T.[Level];

	select [!TItemRole!Array] = null, [Id!!Id] = r.[Uid], r.Kind, r.[Name], r.Memo, 
		r.Color, r.HasPrice, r.IsStock, r.ExType, CostItem = ci.[Uid],
		[Accounts!TItemRoleAcc!Array] = null,
		[!TApp.ItemRoles!ParentId] = 1
	from cat.ItemRoles r 
		left join cat.CostItems ci on r.TenantId = ci.TenantId and r.CostItem = ci.Id
	where r.TenantId = @TenantId and r.Void = 0;

	select [!TItemRoleAcc!Array] = null, [Plan] = pl.[Uid], Account = acc.[Uid], AccKind = ak.[Uid],
		[!TItemRole.Accounts!ParentId] = ir.[Uid]
	from cat.ItemRoleAccounts ira
		inner join cat.ItemRoles ir on ira.TenantId = ir.TenantId and ira.[Role] = ir.[Id]
		inner join acc.Accounts pl on ira.TenantId = pl.TenantId and ira.[Plan] = pl.[Id]
		inner join acc.Accounts acc on ira.TenantId = acc.TenantId and ira.[Account] = acc.[Id]
		inner join acc.AccKinds ak on ira.TenantId = ak.TenantId and ira.[AccKind] = ak.[Id]
	where ira.TenantId = @TenantId and ir.Void = 0;

	select [!TCostItem!Array] = null, [Id!!Id] = ci.[Uid], ci.[Name], ci.[Memo], ci.IsFolder,
		ParentItem = cp.[Uid], [!TApp.CostItems!ParentId] = 1
	from cat.CostItems ci
		left join cat.CostItems cp on ci.TenantId = cp.TenantId and ci.Parent = cp.Id
	where ci.TenantId = @TenantId and ci.Void = 0;

	select [!TAutonum!Array] = null, [Uid!!Id] = an.[Uid], an.[Name], an.[Memo], an.[Period], an.Pattern,
		[!TApp.Autonums!ParentId] = 1
	from doc.Autonums an
	where an.TenantId = @TenantId and an.Void = 0;


	-- OPERATIONS
	select [!TOperation!Array] = null, [Id!!Id] = o.[Uid],
		o.[Name], o.[Memo], o.[Form], Autonum = an.[Uid], [Transactions!TOpTrans!Array] = null,
		[Store!TOpStore!Array] = null, [Cash!TOpCash!Array] = null, [Settle!TOpSettle!Array] = null,
		[PrintForms!TOpPrintForm!Array] = null, [Links!TOpLink!Array] = null,
		[MenuLinks!TOpMenuLink!Array] = null, 
		[!TApp.Operations!ParentId] = 1
	from doc.Operations o
		left join doc.Autonums an on o.TenantId = an.TenantId and o.Autonum = an.Id
	where o.TenantId = @TenantId and o.Void = 0;

	select [!TOpTrans!Array] = null, ot.RowNo, ot.RowKind, [Plan] = pl.[Uid], 
		Dt = dt.[Uid], Ct = ct.[Uid], DtAccMode, DtSum, DtRow, DtAccKind = dtack.[Uid],
		CtAccMode, CtSum, CtRow, CtAccKind =  ctack.[Uid],
		[!TOperation.Transactions!ParentId] = o.[Uid]
	from doc.OpTrans ot inner join doc.Operations o on ot.TenantId = o.TenantId and ot.Operation = o.Id
		left join acc.Accounts pl on ot.TenantId = pl.TenantId and ot.[Plan] = pl.Id
		left join acc.Accounts dt on ot.TenantId = dt.TenantId and ot.[Dt] = dt.Id
		left join acc.Accounts ct on ot.TenantId = ct.TenantId and ot.[Ct] = ct.Id
		left join acc.AccKinds dtack on ot.TenantId = dtack.TenantId and ot.DtAccKind = dtack.Id
		left join acc.AccKinds ctack on ot.TenantId = ctack.TenantId and ot.CtAccKind = ctack.Id
	where ot.TenantId = @TenantId and o.Void = 0;

	select [!TOpStore!Array] = null, ot.RowNo, ot.RowKind, IsIn, IsOut, Factor, 
		[!TOperation.Store!ParentId] = o.[Uid]
	from doc.OpStore ot inner join doc.Operations o on ot.TenantId = o.TenantId and ot.Operation = o.Id
	where ot.TenantId = @TenantId and o.Void = 0;

	select [!TOpCash!Array] = null, IsIn, IsOut, Factor, 
		[!TOperation.Cash!ParentId] = o.[Uid]
	from doc.OpCash ot inner join doc.Operations o on ot.TenantId = o.TenantId and ot.Operation = o.Id
	where ot.TenantId = @TenantId and o.Void = 0;

	select [!TOpSettle!Array] = null, IsInc, IsDec, Factor, 
		[!TOperation.Settle!ParentId] = o.[Uid]
	from doc.OpSettle ot inner join doc.Operations o on ot.TenantId = o.TenantId and ot.Operation = o.Id
	where ot.TenantId = @TenantId and o.Void = 0;

	select [!TOpPrintForm!Array] = null, [PrintForm] = opf.PrintForm,
		[!TOperation.PrintForms!ParentId] = o.[Uid]
	from doc.OpPrintForms opf 
		inner join doc.Operations o on opf.TenantId = o.TenantId and opf.Operation = o.Id
	where opf.TenantId = @TenantId and o.Void = 0;

	select [!TOpLink!Array] = null, ol.[Category], ol.[Type], ol.[Memo], Operation = o.[Uid],
		[!TOperation.Links!ParentId] = p.[Uid]
	from doc.OperationLinks ol
		inner join doc.Operations p on ol.TenantId = p.TenantId and ol.Parent = p.Id
		inner join doc.Operations o on ol.TenantId = o.TenantId and ol.Operation = o.Id
	where ol.TenantId = @TenantId and p.Void = 0;

	select [!TOpMenuLink!Array] = null, oml.Menu,
		[!TOperation.MenuLinks!ParentId] = o.[Uid]
	from ui.OpMenuLinks oml 
		inner join doc.Operations o on oml.TenantId = o.TenantId and oml.Operation = o.Id
	where oml.TenantId = @TenantId and o.Void = 0;
end
go
------------------------------------------------
drop procedure if exists app.[Application.Upload.Metadata];
drop procedure if exists app.[Application.Upload.Update];
drop type if exists app.[Application.AccKind.TableType];
drop type if exists app.[Application.Account.TableType];
drop type if exists app.[Application.CostItem.TableType];
drop type if exists app.[Application.ItemRole.TableType];
drop type if exists app.[Application.ItemRoleAcc.TableType];
drop type if exists app.[Application.Operation.TableType];
drop type if exists app.[Application.OpTrans.TableType];
drop type if exists app.[Application.OpStore.TableType];
drop type if exists app.[Application.OpCash.TableType];
drop type if exists app.[Application.OpSettle.TableType];
drop type if exists app.[Application.OpPrintForms.TableType];
drop type if exists app.[Application.OpLink.TableType];
drop type if exists app.[Application.OpMenuLink.TableType];
drop type if exists app.[Application.Autonum.TableType];
go
------------------------------------------------
create type app.[Application.AccKind.TableType] as table
(
	[Uid] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create type app.[Application.Account.TableType] as table
(
	[Uid] uniqueidentifier,
	[Plan] uniqueidentifier, 
	[ParentAcc] uniqueidentifier,
	[Level] int,
	IsFolder bit,
	[Code] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	IsItem bit,
	IsAgent bit,
	IsWarehouse bit,
	IsBankAccount bit,
	IsCash bit,
	IsContract bit,
	IsRespCenter bit,
	IsCostItem bit
)
go
------------------------------------------------
create type app.[Application.ItemRole.TableType] as table
(
	[Id] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Kind] nvarchar(16),
	[Color] nvarchar(32),
	HasPrice bit,
	IsStock bit,
	ExType nchar(1),
	CostItem uniqueidentifier
)
go
------------------------------------------------
create type app.[Application.CostItem.TableType] as table
(
	[Id] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	IsFolder bit,
	ParentItem uniqueidentifier
)
go
------------------------------------------------
create type app.[Application.ItemRoleAcc.TableType] as table
(
	[ParentId] uniqueidentifier,
	[Plan] uniqueidentifier,
	[Account] uniqueidentifier,
	[AccKind] uniqueidentifier
)
go
------------------------------------------------
create type app.[Application.Operation.TableType] as table
(
	[Id] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	[Form] nvarchar(16),
	[Autonum] uniqueidentifier
);
go
------------------------------------------------
create type app.[Application.OpTrans.TableType] as table
(
	[ParentId] uniqueidentifier,
	RowNo int,
	[Plan] uniqueidentifier,
	[Dt] uniqueidentifier,
	[Ct] uniqueidentifier,
	RowKind nvarchar(16),
	DtAccMode nchar(1), 
	DtSum nchar(1), 
	DtRow nchar(1),
	DtAccKind uniqueidentifier,
	DtWarehouse nchar(1),
	CtAccMode nchar(1),
	CtSum nchar(1),
	CtRow nchar(1),
	CtAccKind uniqueidentifier
);
go
------------------------------------------------
create type app.[Application.OpStore.TableType] as table
(
	[ParentId] uniqueidentifier,
	RowNo int,
	RowKind nvarchar(16),
	IsIn bit,
	IsOut bit,
	Factor smallint
);
go
------------------------------------------------
create type app.[Application.OpCash.TableType] as table
(
	[ParentId] uniqueidentifier,
	IsIn bit,
	IsOut bit,
	Factor smallint
);
go
------------------------------------------------
create type app.[Application.OpSettle.TableType] as table
(
	[ParentId] uniqueidentifier,
	IsInc bit,
	IsDec bit,
	Factor smallint
);
go
------------------------------------------------
create type app.[Application.OpPrintForms.TableType] as table
(
	[ParentId] uniqueidentifier,
	PrintForm nvarchar(16)
)
go
------------------------------------------------
create type app.[Application.OpLink.TableType] as table
(
	[ParentId] uniqueidentifier,
	[Category] nvarchar(32),
	[Type] nvarchar(32),
	[Memo] nvarchar(255),
	Operation uniqueidentifier
);
go
------------------------------------------------
create type app.[Application.OpMenuLink.TableType] as table
(
	[ParentId] uniqueidentifier,
	Menu nvarchar(32)
);
go
------------------------------------------------
create type app.[Application.Autonum.TableType] as table
(
	[Uid] uniqueidentifier,
	[Name] nvarchar(255),
	[Period] nchar(1),
	Pattern nvarchar(255),
	[Memo] nvarchar(255)
);
go
------------------------------------------------
create or alter procedure app.[Application.Upload.Metadata]
as
begin
	set nocount on;

	declare @AccKinds app.[Application.AccKind.TableType];
	declare @Accounts app.[Application.Account.TableType];
	declare @CostItems app.[Application.CostItem.TableType];
	declare @ItemRoles app.[Application.ItemRole.TableType];
	declare @ItemRoleAcc app.[Application.ItemRoleAcc.TableType];
	declare @Operations app.[Application.Operation.TableType];
	declare @OpTrans app.[Application.OpTrans.TableType];
	declare @OpStore app.[Application.OpStore.TableType];
	declare @OpCash app.[Application.OpCash.TableType];
	declare @OpSettle app.[Application.OpSettle.TableType];
	declare @OpPrintForms app.[Application.OpPrintForms.TableType];
	declare @OpLinks app.[Application.OpLink.TableType];
	declare @OpMenuLinks app.[Application.OpMenuLink.TableType];
	declare @Autonums app.[Application.Autonum.TableType];

	select [AccKinds!Application.AccKinds!Metadata] = null, * from @AccKinds;
	select [Accounts!Application.Accounts!Metadata] = null, * from @Accounts;
	select [CostItems!Application.CostItems!Metadata] = null, * from @CostItems;
	select [ItemRoles!Application.ItemRoles!Metadata] = null, * from @ItemRoles;
	select [ItemRoleAcc!Application.ItemRoles.Accounts!Metadata] = null, * from @ItemRoleAcc;
	select [Operations!Application.Operations!Metadata] = null, * from @Operations;
	select [OpTrans!Application.Operations.Transactions!Metadata] = null, * from @OpTrans;
	select [OpStore!Application.Operations.Store!Metadata] = null, * from @OpStore;
	select [OpCash!Application.Operations.Cash!Metadata] = null, * from @OpCash;
	select [OpSettle!Application.Operations.Settle!Metadata] = null, * from @OpSettle;
	select [OpPrintForms!Application.Operations.PrintForms!Metadata] = null, * from @OpPrintForms;
	select [OpLinks!Application.Operations.Links!Metadata] = null, * from @OpLinks;
	select [OpMenuLinks!Application.Operations.MenuLinks!Metadata] = null, * from @OpMenuLinks;
	select [Autonums!Application.Autonums!Metadata] = null, * from @Autonums;
end
go
------------------------------------------------
create or alter procedure app.[Application.Upload.Update]
@TenantId int = 1,
@UserId bigint,
@AccKinds app.[Application.AccKind.TableType] readonly,
@Accounts app.[Application.Account.TableType] readonly,
@CostItems app.[Application.CostItem.TableType] readonly,
@ItemRoles app.[Application.ItemRole.TableType] readonly,
@ItemRoleAcc app.[Application.ItemRoleAcc.TableType] readonly,
@Operations app.[Application.Operation.TableType] readonly,
@OpTrans app.[Application.OpTrans.TableType] readonly,
@OpStore app.[Application.OpStore.TableType] readonly,
@OpCash app.[Application.OpCash.TableType] readonly,
@OpSettle app.[Application.OpSettle.TableType] readonly,
@OpPrintForms app.[Application.OpPrintForms.TableType] readonly,
@OpLinks app.[Application.OpLink.TableType] readonly,
@OpMenuLinks app.[Application.OpMenuLink.TableType] readonly,
@Autonums app.[Application.Autonum.TableType] readonly
as
begin
	set nocount on
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Autonums for xml auto);
	throw 60000, @xml, 0;
	*/

	-- account kinds
	merge acc.AccKinds as t
	using @AccKinds as s
	on t.TenantId = @TenantId and t.[Uid] = s.[Uid]
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.Void = 0
	when not matched by target then insert 
		(TenantId, [Uid], [Name], [Memo]) values
		(@TenantId, s.[Uid], s.[Name], s.[Memo]);

	-- accounts - step 1 - properties
	merge acc.Accounts as t 
	using @Accounts as s
	on t.TenantId = @TenantId and t.[Uid] = s.[Uid]
	when matched then update set
		t.Void = 0,
		t.[Name] = s.[Name],
		t.Code = s.Code,
		t.Memo = s.Memo,
		t.IsFolder = isnull(s.IsFolder, 0),
		t.IsItem = s.IsItem, IsAgent = s.IsAgent, t.IsWarehouse = s.IsWarehouse,
		t.IsBankAccount = s.IsBankAccount, t.IsCash = s.IsCash, t.IsContract = s.IsContract,
		t.IsRespCenter = s.IsRespCenter, t.IsCostItem = s.IsCostItem
	when not matched by target then insert
		(TenantId, [Uid], [Name], Code, [Memo], IsFolder, 
			IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, IsContract, IsRespCenter, IsCostItem) values
		(@TenantId, s.[Uid], s.[Name], s.Code, s.Memo, isnull(s.IsFolder, 0),
			s.IsItem, s.IsAgent, s.IsWarehouse, s.IsBankAccount, s.IsCash, s.IsContract, s.IsRespCenter, s.IsCostItem);

	-- accounts - step 2 - plan & parent
	with T as (
		select Id = a.Id, [Plan] = pl.Id, Parent = par.Id
		from @Accounts s inner join acc.Accounts a on a.TenantId = @TenantId and a.[Uid] = s.[Uid]
			left join acc.Accounts pl on pl.TenantId = @TenantId and pl.[Uid] = s.[Plan]
			left join acc.Accounts par on par.TenantId = @TenantId and par.[Uid] = s.[ParentAcc]
	)
	merge acc.Accounts as t 
	using T as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.Parent = s.Parent,
		t.[Plan] = s.[Plan];

	-- cost items - step 1
	merge cat.CostItems as t
	using @CostItems as s
	on t.TenantId = @TenantId and t.[Uid] = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.IsFolder = isnull(s.[IsFolder], 0)
	when not matched by target then insert
		(TenantId, [Uid], [Name], Memo, IsFolder) values
		(@TenantId, s.Id, s.[Name], s.Memo, isnull(s.IsFolder, 0));

	-- cost items - step 2
	with T as (
		select Id = t.Id, Parent = px.Id
		from @CostItems s inner join cat.CostItems t on t.TenantId = @TenantId and s.Id = t.[Uid]
		left join cat.CostItems px on px.TenantId = @TenantId and s.ParentItem = px.[Uid]
	)
	update cat.CostItems set Parent = T.Id
	from T inner join cat.CostItems ci on ci.TenantId = @TenantId and T.Id = ci.Id;

	-- item roles
	declare @itemrolestable table(id bigint, [uid] uniqueidentifier);
	merge cat.ItemRoles as t
	using (
		select s.Id, s.[Name], s.[Memo], s.Kind, s.Color, 
			s.HasPrice, s.IsStock, s.ExType, CostItem = ci.Id
		from @ItemRoles s 
		left join cat.CostItems ci on ci.TenantId=@TenantId and s.CostItem = ci.[Uid]
	) as s
	on t.TenantId = @TenantId and t.[Uid] = s.[Id]
	when matched then update set
		t.Void = 0,
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.Kind = s.Kind,
		t.Color = s.Color,
		t.HasPrice = s.HasPrice,
		t.IsStock = s.IsStock,
		t.ExType = s.ExType,
		t.CostItem = s.CostItem
	when not matched by target then insert
		(TenantId, [Uid], [Name], Memo, Kind, Color, HasPrice, IsStock, ExType) values
		(@TenantId, s.[Id], s.[Name], s.Memo, s.Kind, s.Color, s.HasPrice, s.IsStock, s.ExType)
	output inserted.Id, inserted.[Uid] into @itemrolestable(id, [uid]);


	delete from cat.ItemRoleAccounts where TenantId = @TenantId;
	with T as (
		select [Role] =  ir.id, Account = a.Id, AccKind = ak.Id, [Plan] = pl.Id
		from  @ItemRoleAcc s inner join @itemrolestable ir on s.ParentId = ir.[uid]
		inner join acc.Accounts pl on pl.TenantId = @TenantId and pl.[Uid] = s.[Plan]
		inner join acc.Accounts a on a.TenantId = @TenantId and a.[Uid] = s.Account
		inner join acc.AccKinds ak on ak.TenantId = @TenantId and ak.[Uid] = s.AccKind
	)
	insert into cat.ItemRoleAccounts(TenantId, [Role], [Plan], Account, AccKind)
	select @TenantId, [Role], [Plan], Account, AccKind from T;
	

	-- autnums
	merge doc.Autonums as t
	using @Autonums as s
	on t.TenantId = @TenantId and t.[Uid] = s.[Uid]
	when matched then update set
		t.[Name] = s.[Name],
		t.[Period] = s.[Period],
		t.Pattern = s.Pattern,
		t.[Memo] = s.[Memo],
		t.Void = 0
	when not matched by target then insert 
		(TenantId, [Uid], [Name], [Period], Pattern, [Memo]) values
		(@TenantId, s.[Uid], s.[Name], s.[Period], s.Pattern, s.[Memo]);

	-- operations
	declare @operationstable table(id bigint, [uid] uniqueidentifier);

	with OT as (
		select Id = o.Id, o.[Name], o.Memo, o.Form, Autonum = ans.Id
		from @Operations o left join @Autonums an on o.Autonum = an.[Uid]
		left join doc.Autonums ans on ans.TenantId = @TenantId and ans.[Uid] = an.[Uid]

	)
	merge doc.Operations as t
	using OT as s
	on t.TenantId = @TenantId and t.[Uid] = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Form] = s.[Form],
		t.[Autonum] = s.Autonum
	when not matched by target then insert
		(TenantId, [Uid], [Name], Memo, [Form], Autonum) values
		(@TenantId, s.Id, s.[Name], s.Memo, s.[Form], s.Autonum)
	output inserted.Id, inserted.[Uid] into @operationstable(id, [uid]);

	delete from doc.OpTrans where TenantId = @TenantId;
	with T as (
		select [Operation] =  op.id, RowKind = isnull(s.RowKind, N''), s.RowNo, [Plan] = pl.Id, [Dt] = dt.Id, [Ct] = ct.Id,
			DtAccKind = dtak.Id, CtAccKind = ctak.Id, s.DtAccMode, s.CtAccMode, s.DtRow, s.CtRow,
			s.DtSum, s.CtSum
		from  @OpTrans s inner join @operationstable op on s.ParentId = op.[uid]
			inner join acc.Accounts pl on pl.TenantId = @TenantId and pl.[Uid] = s.[Plan]
			left join acc.Accounts dt on dt.TenantId = @TenantId and dt.[Uid] = s.Dt
			left join acc.Accounts ct on ct.TenantId = @TenantId and ct.[Uid] = s.Ct
			left join acc.AccKinds dtak on dtak.TenantId = @TenantId and dtak.[Uid] = s.DtAccKind
			left join acc.AccKinds ctak on ctak.TenantId = @TenantId and ctak.[Uid] = s.CtAccKind
	)
	insert into doc.OpTrans(TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct, 
		DtAccMode, DtAccKind, DtSum, DtRow, CtAccMode, CtAccKind, CtRow, CtSum)
	select @TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct,
		DtAccMode, DtAccKind, DtSum, DtRow, CtAccMode, CtAccKind, CtRow, CtSum
	from T;

	delete from doc.OpStore where TenantId = @TenantId;
	with T as (
		select [Operation] =  op.id, RowKind = isnull(s.RowKind, N''), s.RowNo, IsIn = isnull(IsIn, 0), IsOut = isnull(IsOut, 0), Factor
		from  @OpStore s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into doc.OpStore(TenantId, Operation, RowNo, RowKind, IsIn, IsOut, Factor)
	select @TenantId, Operation, RowNo, RowKind, IsIn, IsOut, Factor
	from T;

	delete from doc.OpCash where TenantId = @TenantId;
	with T as (
		select [Operation] =  op.id, IsIn = isnull(IsIn, 0), IsOut = isnull(IsOut, 0), Factor
		from  @OpCash s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into doc.OpCash(TenantId, Operation, IsIn, IsOut, Factor)
	select @TenantId, Operation, IsIn, IsOut, Factor
	from T;

	delete from doc.OpSettle where TenantId = @TenantId;
	with T as (
		select [Operation] =  op.id, IsInc = isnull(IsInc, 0), IsDec = isnull(IsDec, 0), Factor
		from  @OpSettle s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into doc.OpSettle(TenantId, Operation, IsInc, IsDec, Factor)
	select @TenantId, Operation, IsInc, IsDec, Factor
	from T;


	delete from doc.OpPrintForms where TenantId = @TenantId;
	with T as (
		select [Operation] = op.id, s.PrintForm
		from @OpPrintForms s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into doc.OpPrintForms(TenantId, Operation, PrintForm)
	select @TenantId, Operation, PrintForm
	from T;

	delete from doc.OperationLinks where TenantId = @TenantId;
	with T as (
		select [Parent] = op.id, Operation = lo.Id, s.Category, s.[Type], s.Memo
		from @OpLinks s 
			inner join @operationstable op on s.ParentId = op.[uid]
			inner join doc.Operations lo on lo.TenantId = @TenantId and s.Operation = lo.[Uid]
	)
	insert into doc.OperationLinks(TenantId, Parent, Operation, Category, [Type], Memo)
	select @TenantId, Parent, Operation, Category, [Type], Memo
	from T;

	delete from ui.OpMenuLinks where TenantId = @TenantId;
	with T as (
		select [Operation] = op.id, s.Menu
		from @OpMenuLinks s inner join @operationstable op on s.ParentId = op.[uid]
	)
	insert into ui.OpMenuLinks(TenantId, Operation, Menu)
	select @TenantId, Operation, Menu
	from T;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @CostItems for xml auto);
	throw 60000, @xml, 0;
	*/

	select [Result!TResult!Object] = null, [Success] = 1;
end
go

