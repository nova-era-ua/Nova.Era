/* Operation */
-------------------------------------------------
create or alter procedure doc.[Operation.Plain.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Operations!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form!TForm!RefId] = o.Form,
		[Journals!TOpJournal!Array] = null
	from doc.Operations o
		inner join doc.Forms df on o.TenantId = df.TenantId and o.Form = df.Id
	where o.TenantId = @TenantId
	order by df.[Order], o.Id;

	select [Forms!TForm!Array] = null, [Id!!Id] = f.Id, [Name!!Name] = f.[Name], f.Category
	from doc.Forms f;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Index]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Menu!TMenu!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo, Category,
		[Children!TOperation!LazyArray] = null
	from doc.FormsMenu
	where TenantId = @TenantId
	order by [Order], Id;

	-- children declaration. same as Children proc
	select [!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[Journals!TOpJournal!Array] = null
	from doc.Operations where 1 <> 1;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;


	select [Operation!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		o.DocumentUrl, [Form!TForm!RefId] = o.Form, [Autonum!TAutonum!RefId] = o.Autonum,
		--[STrans!TSTrans!Array] = null,
		[OpLinks!TOpLink!Array] = null,
		[Trans!TOpTrans!Array] = null, [Store!TOpStore!Array] = null
	from doc.Operations o
	where o.TenantId = @TenantId and o.Id=@Id;

	/*
	-- SIMPLE TRANSACTIONS
	select [!TSTrans!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		[!TOperation.STrans!ParentId] = os.Operation
	from doc.OpSimple os 
	where os.TenantId = @TenantId and os.Operation = @Id;
	*/

	-- ACCOUNT TRANSACTIONS
	select [!TOpTrans!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		[Plan!TAccount!RefId] = [Plan], [Dt!TAccount!RefId] = Dt, [Ct!TAccount!RefId] = Ct, 
		DtAccMode, DtSum, DtRow, CtAccMode, CtSum, CtRow,
		[!TOperation.Trans!ParentId] = ot.Operation,
		[DtAccKind!TAccKind!RefId] = ot.DtAccKind, [CtAccKind!TAccKind!RefId] = ot.CtAccKind
	from doc.OpTrans ot 
	where ot.TenantId = @TenantId and ot.Operation = @Id
	order by ot.RowNo;

	-- STORE TRANSACTIONS
	select [!TOpStore!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		os.IsIn, os.IsOut, IsStorno = cast(case when os.Factor = -1 then 1 else 0 end as bit), 
		[!TOperation.Store!ParentId] = os.Operation
	from doc.OpStore os
	where os.TenantId = @TenantId and os.Operation = @Id
	order by os.RowNo;

	select [!TOpLink!Array] = null, [Id!!Id] = ol.Id, [Type], [Category],
		[Operation.Id!TOper!Id] = o.Id, [Operation.Name!TOper!Name] = o.[Name],
		[!TOperation.OpLinks!ParentId] = ol.Parent
	from doc.OperationLinks ol 
		inner join doc.Operations o on ol.TenantId = o.TenantId and ol.Operation = o.Id
	where ol.TenantId = @TenantId and ol.Parent = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = a.Id, a.Code, [Name!!Name] = a.[Name],
		a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash
	from doc.OpTrans ot 
		left join acc.Accounts a on ot.TenantId = a.TenantId and a.Id in (ot.[Plan], ot.Dt, ot.Ct)
	where ot.TenantId = @TenantId and ot.Operation = @Id
	group by a.Id, a.Code, a.[Name], a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash;

	select [Forms!TForm!Array] = null, [Id!!Id] = df.Id, [Name!!Name] = df.[Name], [Category], InOut, [Url],
		[RowKinds!TRowKind!Array] = null
	from doc.Forms df
	where df.TenantId = @TenantId
	order by df.[Order], df.Id;

	select [Menu!TMenu!Array] = null, [Id!!Id] = fm.Id, [Name], fm.[Category], 
		Checked = case when ml.Menu is not null then 1 else 0 end
	from doc.FormsMenu fm
		left join ui.OpMenuLinks ml on fm.TenantId = ml.TenantId and ml.Operation = @Id and fm.Id = ml.Menu
	where fm.TenantId = @TenantId
	order by fm.[Order];

	select [PrintForms!TPrintForm!Array] = null, [Id!!Id] = pf.Id, [Name], pf.[Category], 
		Checked = case when pfl.PrintForm is not null then 1 else 0 end
	from doc.PrintForms pf
		left join doc.OpPrintForms pfl on pf.TenantId = pfl.TenantId and pfl.Operation = @Id and pf.Id = pfl.PrintForm
	where pf.TenantId = @TenantId
	order by pf.[Order];

	select [Autonums!TAutonum!Array] = null, [Id!!Id] = an.Id, [Name]
	from doc.Autonums an
	where an.TenantId = @TenantId and an.Void = 0
	order by an.[Name];


	select [!TRowKind!Array] = null, [Id!!Id] = rk.Id, [Name!!Name] = rk.[Name], [!TForm.RowKinds!ParentId] = rk.Form
	from doc.FormRowKinds rk where rk.TenantId = @TenantId
	order by rk.[Order];

	select [AccountKinds!TAccKind!Array] = null, [Id!!Id] = ak.Id, [Name!!Name] = ak.[Name]
	from acc.AccKinds ak
	where ak.TenantId = @TenantId
	order by ak.Id;
end
go
-------------------------------------------------
drop procedure if exists doc.[Operation.Metadata];
drop procedure if exists doc.[Operation.Update];
drop type if exists doc.[Operation.TableType];
drop type if exists doc.[OpStore.TableType];
drop type if exists doc.[OpTrans.TableType];
drop type if exists doc.[OpMenu.TableType]
drop type if exists doc.[OpPrintForm.TableType]
drop type if exists doc.[OpLink.TableType];
go
-------------------------------------------------
create type doc.[Operation.TableType]
as table(
	Id bigint null,
	[Menu] nvarchar(32),
	[Form] nvarchar(16),
	[DocumentUrl] nvarchar(255),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Autonum bigint
)
go
-------------------------------------------------
create type doc.[OpMenu.TableType]
as table(
	Id nvarchar(32),
	Checked bit
)
go
-------------------------------------------------
create type doc.[OpPrintForm.TableType]
as table(
	Id nvarchar(16),
	Checked bit
)
go
-------------------------------------------------
create type doc.[OpLink.TableType]
as table(
	Id bigint,
	[Type] nvarchar(32),
	[Category] nvarchar(32),
	Operation bigint
)
go
-------------------------------------------------
create type doc.[OpStore.TableType]
as table(
	Id bigint,
	RowNo int,
	RowKind nvarchar(8),
	IsIn bit,
	IsOut bit,
	IsStorno bit
)
go
-------------------------------------------------
create type doc.[OpTrans.TableType]
as table(
	Id bigint,
	RowNo int,
	RowKind nvarchar(8),
	[Plan] bigint,
	[Dt] bigint,
	[Ct] bigint,
	DtAccMode nchar(1),
	DtAccKind bigint,
	DtRow nchar(1),
	DtSum nchar(1),
	CtAccMode nchar(1),
	CtAccKind bigint,
	CtRow nchar(1),
	CtSum nchar(1)
)
go
------------------------------------------------
create or alter procedure doc.[Operation.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Operation doc.[Operation.TableType];
	declare @OpStore doc.[OpStore.TableType];
	declare @OpTrans doc.[OpTrans.TableType];
	declare @OpMenu doc.[OpMenu.TableType];
	declare @OpPrintForm doc.[OpPrintForm.TableType];
	declare @OpLinks doc.[OpLink.TableType];
	select [Operation!Operation!Metadata] = null, * from @Operation;
	select [Store!Operation.Store!Metadata] = null, * from @OpStore;
	select [Trans!Operation.Trans!Metadata] = null, * from @OpTrans;
	select [Menu!Menu!Metadata] = null, * from @OpMenu;
	select [PrintForms!PrintForms!Metadata] = null, * from @OpPrintForm;
	select [Links!Operation.OpLinks!Metadata] = null, * from @OpLinks;
end
go
------------------------------------------------
create or alter procedure doc.[Operation.Update]
@TenantId bigint = 1,
@UserId bigint,
@Operation doc.[Operation.TableType] readonly,
@Store doc.[OpStore.TableType] readonly,
@Trans doc.[OpTrans.TableType] readonly,
@Menu doc.[OpMenu.TableType] readonly,
@Links doc.[OpLink.TableType] readonly,
@PrintForms doc.[OpPrintForm.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @rtable table(id bigint);
	declare @Id bigint;

	merge doc.Operations as t
	using @Operation as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Form] = s.[Form],
		t.[DocumentUrl] = s.[DocumentUrl],
		t.Autonum = s.[Autonum]
	when not matched by target then insert
		(TenantId, [Name], Form, Memo, DocumentUrl, Autonum) values
		(@TenantId, s.[Name], s.Form, s.Memo, s.DocumentUrl, s.Autonum)
	output inserted.Id into @rtable(id);
	select top(1) @Id = id from @rtable;

	merge doc.OpStore as t
	using @Store as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowNo = s.RowNo,
		t.RowKind = isnull(s.RowKind, N''),
		t.IsIn = s.IsIn,
		t.IsOut = s.IsOut,
		t.Factor = case when s.IsStorno = 1 then -1 else 1 end
	when not matched by target then insert
		(TenantId, Operation, RowNo, RowKind, IsIn, IsOut, Factor) values
		(@TenantId, @Id, RowNo, isnull(RowKind, N''), s.IsIn, s.IsOut, case when s.IsStorno = 1 then -1 else 1 end)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

	merge doc.OpTrans as t
	using @Trans as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowNo = s.RowNo,
		t.RowKind = isnull(s.RowKind, N''),
		t.[Plan] = s.[Plan],
		t.[Dt] = s.[Dt],
		t.[Ct] = s.[Ct],
		t.DtAccMode = s.DtAccMode,
		t.DtAccKind = s.DtAccKind,
		t.CtAccMode = s.CtAccMode,
		t.CtAccKind = s.CtAccKind,
		t.DtRow = s.DtRow,
		t.CtRow = s.CtRow,
		t.DtSum = s.DtSum,
		t.CtSum = s.CtSum
	when not matched by target then insert
		(TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct, DtAccMode, DtAccKind, CtAccMode, CtAccKind, 
			DtRow, CtRow, DtSum, CtSum) values
		(@TenantId, @Id, RowNo, isnull(RowKind, N''), s.[Plan], s.Dt, s.Ct, s.DtAccMode, s.DtAccKind, s.CtAccMode, s.CtAccKind, 
			s.DtRow, s.CtRow, s.DtSum, s.CtSum)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	with OM as (select Id from @Menu where Checked = 1)
	merge ui.OpMenuLinks as t
	using OM as s
	on t.TenantId = @TenantId and t.Operation = @Id and t.Menu = s.Id
	when not matched by target then insert
		(TenantId, Operation, Menu) values
		(@TenantId, @Id, s.Id)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

	with OPF as (select Id from @PrintForms where Checked = 1)
	merge doc.OpPrintForms as t
	using OPF as s
	on t.TenantId = @TenantId and t.Operation = @Id and t.PrintForm = s.Id
	when not matched by target then insert
		(TenantId, Operation, PrintForm) values
		(@TenantId, @Id, s.Id)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

	merge doc.OperationLinks as t
	using @Links as s
	on t.TenantId = @TenantId and t.Id = s.Id and t.Parent = @Id
	when matched then update set
		t.[Type] = s.[Type],
		t.Category = s.[Category],
		t.Operation = s.Operation
	when not matched by target then insert
		(TenantId, Parent, Operation, [Type], [Category]) values
		(@TenantId, @Id, s.Operation, s.[Type], s.[Category])
	when not matched by source and t.TenantId = @TenantId and t.Parent = @Id then delete;

	exec doc.[Operation.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @Id;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Plain.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	if exists(select * from doc.Documents where TenantId = @TenantId and Operation = @Id) or
		exists(select * from doc.OperationLinks where TenantId = @TenantId and Operation = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	begin tran;
	delete from doc.OpTrans where TenantId = @TenantId and Operation = @Id;
	delete from ui.OpMenuLinks where TenantId = @TenantId and Operation = @Id;
	delete from doc.OperationLinks where TenantId = @TenantId and Parent = @Id;
	delete from doc.Operations where TenantId = @TenantId and Id = @Id;
	commit tran;

end
go
