/* Document Apply */
------------------------------------------------
create or alter procedure doc.[Document.Apply.Account.ByRows]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @exclude bit = 0;
	if 1 = (select IncludeServiceInCost from doc.DocumentExtra where TenantId = @TenantId and Id = @Id)
		set @exclude = 1;

	declare @trans table(TrNo int, RowNo int, DtCt smallint, Acc bigint, CorrAcc bigint, [Plan] bigint, 
		Detail bigint, Item bigint, RowMode nchar(1),
		Wh bigint, CashAcc bigint, [Date] date, Agent bigint, Company bigint, CostItem bigint,
		[Contract] bigint, CashFlowItem bigint, RespCenter bigint, Project bigint,
		Qty float, [Sum] money, ESum money, SumMode nchar(1), CostSum money, [ResultSum] money);

	-- DOCUMENT with ROWS
	with TR as (
		select 
			Dt = case ot.DtAccMode 
				when N'R' then ird.Account 
				when N'D' then irdocdt.Account
				else ot.Dt 
			end,
			Ct = case ot.CtAccMode 
				when N'R' then irc.Account
				when N'D' then irdocct.Account
				else ot.Ct 
			end,
			TrNo = ot.RowNo, dd.[RowNo], Detail = dd.Id, dd.[Item], Qty = dd.Qty * ot.Factor, [Sum] = dd.[Sum] * ot.Factor, 
			ESum = dd.ESum * ot.Factor,
			[Plan] = ot.[Plan], DtRow = isnull(ot.DtRow, N''), CtRow = isnull(ot.CtRow, N''),
			DtSum = isnull(ot.DtSum, N''), CtSum = isnull(ot.CtSum, N''),
			d.[Date], d.Agent, d.Company, d.RespCenter, dd.CostItem, d.WhFrom, d.WhTo, d.CashAccFrom, d.CashAccTo,
			d.[Contract], d.[CashFlowItem], d.Project
		from doc.DocDetails dd
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join doc.OpTrans ot on dd.TenantId = ot.TenantId and (dd.Kind = ot.RowKind or ot.RowKind = N'All')
			left join cat.ItemRoleAccounts ird on ird.TenantId = dd.TenantId and ird.[Role] = isnull(dd.ItemRoleTo, dd.ItemRole) and ird.AccKind = ot.DtAccKind and ird.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts irc on irc.TenantId = dd.TenantId and irc.[Role] = dd.ItemRole and irc.AccKind = ot.CtAccKind and irc.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts irdocdt on irdocdt.TenantId = d.TenantId and irdocdt.[Role] = d.ItemRole and irdocdt.AccKind = ot.DtAccKind and irdocdt.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts irdocct on irdocct.TenantId = d.TenantId and irdocct.[Role] = d.ItemRole and irdocct.AccKind = ot.CtAccKind and irdocct.[Plan] = ot.[Plan]
		where dd.TenantId = @TenantId and dd.Document = @Id and ot.Operation = @Operation 
			and (@exclude = 0 or Kind <> N'Service')
			--and (ot.DtRow = N'R' or ot.CtRow = N'R')
	)
	insert into @trans(TrNo, RowNo, DtCt, Acc, CorrAcc, [Plan], [Detail], Item, RowMode, Wh, CashAcc, 
		[Date], Agent, Company, RespCenter, Project, CostItem, [Contract],  CashFlowItem, Qty,[Sum], ESum, SumMode, CostSum, ResultSum)

	select TrNo, RowNo, DtCt = 1, Acc = Dt, CorrAcc = Ct, [Plan], Detail, Item, RowMode = DtRow, Wh = isnull(WhTo, WhFrom), CashAcc = CashAccTo,
		[Date], Agent, Company, RespCenter, Project, CostItem, [Contract], CashFlowItem, [Qty], [Sum], ESum, SumMode = DtSum, CostSum = 0, ResultSum = [Sum]
		from TR
	union all 
	select TrNo, RowNo, DtCt = -1, Acc = Ct, CorrAcc = Dt, [Plan], Detail, Item, RowMode = CtRow, Wh = isnull(WhFrom, WhTo), CashAcc = CashAccFrom,
		[Date], Agent, Company, RespCenter, Project, CostItem, [Contract], CashFlowItem, [Qty], [Sum], ESum, SumMode = CtSum, CostSum = 0, ResultSum = [Sum]
		from TR;

	if exists(select * from @trans where SumMode = N'S')
	begin
		-- calc self cost
		with W(item, ssum) as (
			select t.Item, [sum] = sum(j.[Sum]) / sum(j.Qty)
			from jrn.Journal j 
			  inner join @trans t on j.Item = t.Item and j.Account = t.Acc and j.DtCt = 1 and j.[Date] <= t.[Date]
			where j.TenantId = @TenantId and t.SumMode = N'S'
			group by t.Item
		)
		update @trans set CostSum = W.ssum * t.Qty
		from @trans t inner join W on t.Item = W.item
		where t.SumMode = N'S';
	end

	update @trans set ResultSum = 
		case SumMode
			when N'S' then CostSum
			when N'R' then [Sum] - CostSum
			when N'E' then [ESum]
			else [Sum]
		end,
		Qty = 
		case SumMode
			when N'E' then 0
			else Qty
		end;
	
	insert into jrn.Journal(TenantId, Document, Operation, Detail, TrNo, RowNo, [Date], DtCt, [Plan], Account, CorrAccount, [Sum], [Qty], [Item],
		Company, Agent, Warehouse, CashAccount, [Contract], CashFlowItem, CostItem, RespCenter, Project)
	select TenantId = @TenantId, Document = @Id, Operation = @Operation, Detail = iif(RowMode = N'R', Detail, null), TrNo, RowNo = iif(RowMode = N'R', RowNo, null),
		[Date], DtCt, [Plan], Acc, CorrAcc, [Sum] = sum([ResultSum]), Qty = sum(iif(RowMode = N'R', Qty, 0)),
		Item = iif(RowMode = N'R', Item, null),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter, Project
	from @trans
	group by TrNo, 
		iif(RowMode = N'R', RowNo, null),
		[Date], DtCt, [Plan], Acc, CorrAcc, 
		iif(RowMode = N'R', Item, null),
		iif(RowMode = N'R', Detail, null),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, 
		CostItem, RespCenter, Project
	having sum(ResultSum) <> 0 or sum(iif(RowMode = N'R', Qty, 0)) <> 0
	order by TrNo, RowNo;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.Account.ByDoc]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @trans table(TrNo int, DtCt smallint, Acc bigint, CorrAcc bigint, [Plan] bigint, 
		RowMode nchar(1),
		Wh bigint, CashAcc bigint, [Date] date, Agent bigint, Company bigint, RespCenter bigint, CostItem bigint,
		[Contract] bigint, CashFlowItem bigint, Project bigint, [Sum] money);

	with TR as (
		select 
			Dt = case ot.DtAccMode 
				when N'C' then iraccdt.Account
				when N'D' then irdocdt.Account
				else ot.Dt
			end,
			Ct  = case ot.CtAccMode 
				when N'C' then iraccct.Account
				when N'D' then irdocct.Account
				else ot.Ct
			end,
			TrNo = ot.RowNo, [Sum] = d.[Sum] * ot.Factor,
			[Plan] = ot.[Plan], DtRow = isnull(ot.DtRow, N''), CtRow = isnull(ot.CtRow, N''),
			d.[Date], d.Agent, d.Company, d.RespCenter, d.CostItem, d.WhFrom, d.WhTo, d.CashAccFrom, d.CashAccTo,
			d.[Contract], d.CashFlowItem, d.Project
		from doc.Documents d
			inner join doc.OpTrans ot on d.TenantId = ot.TenantId and ot.RowKind = N''
			left join cat.CashAccounts accdt on d.TenantId = accdt.TenantId and d.CashAccTo = accdt.Id
			left join cat.CashAccounts accct on d.TenantId = accct.TenantId and d.CashAccFrom = accct.Id
			left join cat.ItemRoleAccounts irdocdt on irdocdt.TenantId = d.TenantId and irdocdt.[Role] = d.ItemRole and irdocdt.AccKind = ot.DtAccKind and irdocdt.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts irdocct on irdocct.TenantId = d.TenantId and irdocct.[Role] = d.ItemRole and irdocct.AccKind = ot.CtAccKind and irdocct.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts iraccdt on iraccdt.TenantId = d.TenantId and iraccdt.[Role] = accdt.ItemRole and iraccdt.AccKind = ot.DtAccKind and iraccdt.[Plan] = ot.[Plan]
			left join cat.ItemRoleAccounts iraccct on iraccct.TenantId = d.TenantId and iraccct.[Role] = accct.ItemRole and iraccct.AccKind = ot.CtAccKind and iraccct.[Plan] = ot.[Plan]
		where d.TenantId = @TenantId and d.Id = @Id and ot.Operation = @Operation
	)
	insert into @trans
	select TrNo, DtCt = 1, Acc = Dt, CorrAcc = Ct, [Plan], RowMode = DtRow, Wh = isnull(WhTo, WhFrom), CashAcc = CashAccTo,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, Project, [Sum]
		from TR
	union all 
	select TrNo, DtCt = -1, Acc = Ct, CorrAcc = Dt, [Plan], RowMode = CtRow, Wh = isnull(WhFrom, WhTo), CashAcc = CashAccFrom,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, Project, [Sum]
		from TR;

	insert into jrn.Journal(TenantId, Document, Operation, TrNo, [Date], DtCt, [Plan], Account, CorrAccount, [Sum],
		Company, Agent, Warehouse, CashAccount, [Contract], CashFlowItem, CostItem, RespCenter, Project)
	select TenantId = @TenantId, Document = @Id, Operation = @Operation, TrNo,
		[Date], DtCt, [Plan], Acc, CorrAcc, [Sum] = sum([Sum]),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter, Project
	from @trans
	group by TrNo, [Date], DtCt, [Plan], Acc, CorrAcc, 
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter, Project
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.Account]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	set ansi_warnings off;

	-- ensure empty journal
	delete from jrn.Journal where TenantId = @TenantId and Document = @Id;

	declare @mode nvarchar(10) = N'bydoc';

	if exists(select * from doc.DocDetails where TenantId = @TenantId and Document = @Id)
		exec doc.[Document.Apply.Account.ByRows] @TenantId = @TenantId, @UserId = @UserId, @Operation = @Operation, @Id = @Id
	else
		exec doc.[Document.Apply.Account.ByDoc] @TenantId = @TenantId, @UserId = @UserId, @Operation = @Operation, @Id = @Id
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.Stock]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;


	with TX as 
	(
		select Document = d.Id, Dir = 1, Detail = dd.Id, d.Company, Warehouse = isnull(d.WhTo, d.WhFrom), dd.Item, Qty = dd.Qty * js.Factor, [Sum] = dd.[Sum] * js.Factor, 
			Kind = isnull(dd.Kind, N''), CostItem = isnull(dd.CostItem, d.CostItem), RespCenter, d.Agent, d.[Contract], d.Project
		from doc.DocDetails dd 		
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join doc.OpStore js on js.TenantId = d.TenantId and js.Operation = d.Operation and js.IsIn = 1
		where d.TenantId = @TenantId and d.Id = @Id
		union all
		select Document = d.Id, Dir = -1, Detail = dd.Id, d.Company, Warehouse = isnull(d.WhFrom, d.WhTo), dd.Item, Qty = dd.Qty * js.Factor, [Sum] = dd.[Sum] * js.Factor, 
			Kind = isnull(dd.Kind, N''), CostItem = isnull(dd.CostItem, d.CostItem), RespCenter, d.Agent, d.[Contract], d.Project
		from doc.DocDetails dd 		
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join doc.OpStore js on js.TenantId = d.TenantId and js.Operation = d.Operation and js.IsOut = 1
		where d.TenantId = @TenantId and d.Id = @Id
	)
	insert into jrn.StockJournal(TenantId, Dir, Document, Warehouse, Detail, Company, Item, Qty, [Sum], CostItem, 
		RespCenter, Agent, [Contract], Project)
	select @TenantId, Dir, Document, Warehouse, Detail, Company, Item, Qty, [Sum], CostItem,
		RespCenter, Agent, [Contract], Project
	from TX;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.Cash]
@TenantId int = 1,
@UserId bigint,
@Operation bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from jrn.CashJournal where TenantId = @TenantId and Document = @Id;

	with T as
	(
		select InOut = 1, Document = d.Id, d.[Date], d.Company, d.Agent, d.[Contract], CashAcc = isnull(d.CashAccTo, d.CashAccFrom), [Sum] = d.[Sum] * oc.Factor, d.CostItem, d.RespCenter, d.Project, 
			d.CashFlowItem
		from doc.Documents d
			inner join doc.OpCash oc on oc.TenantId = @TenantId and d.Operation = oc.Operation
		where d.TenantId = @TenantId and d.Id = @Id and oc.IsIn = 1
		union all
		select InOut = -1, Document = d.Id, d.[Date], d.Company, d.Agent, d.[Contract], CashAcc = isnull(d.CashAccFrom, d.CashAccTo), [Sum] = d.[Sum] * oc.Factor, d.CostItem, d.RespCenter, d.Project, 
			d.CashFlowItem
		from doc.Documents d
			inner join doc.OpCash oc on oc.TenantId = @TenantId and d.Operation = oc.Operation
		where d.TenantId = @TenantId and d.Id = @Id and oc.IsOut = 1
	)
	insert into jrn.CashJournal(TenantId, Document, [Date], InOut, [Sum], Company, Agent, [Contract], CashAccount, CashFlowItem, RespCenter, Project)
	select TenantId = @TenantId, Document = @Id, [Date], InOut, [Sum], Company, Agent, [Contract], CashAcc, CashFlowItem, RespCenter, Project
	from T;
end
go
------------------------------------------------
create or alter procedure doc.[Apply.WriteSupplierPrices]
@TenantId int = 1,
@UserId bigint, 
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	with T as(
		select Document = d.Id, Detail = dd.Id, dd.Item, d.Agent, [Date] = cast(d.[Date] as date), dd.Price 
		from doc.DocDetails dd
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join cat.ItemRoles ir on dd.TenantId = ir.TenantId and dd.ItemRole = ir.Id
		where dd.TenantId = @TenantId and dd.Document = @Id and ir.HasPrice = 1
	)
	merge jrn.SupplierPrices as t
	using T as s
	on t.[Date] = s.[Date] and t.Item = s.Item and t.TenantId = @TenantId
	when matched then update set
		t.Document = s.Document,
		t.Detail = s.Detail,
		t.Agent = s.Agent,
		t.Price = isnull(s.Price, 0)
	when not matched by target then insert
		(TenantId, [Date], Agent, Document, Detail, Item, Price) values
		(@TenantId, s.[Date], s.[Agent], s.Document, s.Detail, s.Item, isnull(s.Price, 0));
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply.CheckRems]
@TenantId int = 1,
@Id bigint,
@CheckRems bit
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set @CheckRems = app.fn_IsCheckRems(@TenantId, @CheckRems);
	if @CheckRems = 1
	begin
		declare @res table(Item bigint, [Role] bigint, Qty float);
		with TD as
		(
			select Item, [Role] = dd.ItemRole, Qty = sum(Qty) from doc.DocDetails dd
			where dd.TenantId = @TenantId and dd.Document = @Id and dd.Kind = N'Stock'
			group by Item, dd.ItemRole
		)
		insert into @res(Item, [Role], Qty) select Item, [Role], Qty from TD;

		if exists(
			select * 
			from @res dd left join doc.fn_getDocumentRems(@CheckRems, @TenantId, @Id) t on dd.Item = t.Item and dd.[Role] = t.[Role]
			where dd.Qty > isnull(t.Rem, 0)
		)
		throw 60000, N'UI:@[Error.InsufficientAmount]', 0;
	end
end
go
------------------------------------------------
create or alter procedure doc.[Document.UnApply]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	begin tran;
	delete from jrn.StockJournal where TenantId = @TenantId and Document = @Id;
	delete from jrn.Journal where TenantId = @TenantId and Document = @Id;
	delete from jrn.CashJournal where TenantId= @TenantId and Document = @Id;
	delete from jrn.SupplierPrices where TenantId = @TenantId and Document = @Id;
	update doc.Documents set Done = 0, DateApplied = null
		where TenantId = @TenantId and Id = @Id;
	commit tran;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Apply]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@CheckRems bit = 0
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @operation bigint;
	declare @done bit;
	declare @wsp bit;

	select @operation = d.Operation, @done = d.Done, @wsp = de.WriteSupplierPrices
	from doc.Documents d
		left join doc.DocumentExtra de on d.TenantId = de.TenantId and d.Id = de.Id
	where d.TenantId = @TenantId and d.Id=@Id;

	if 1 = @done
		throw 60000, N'UI:@[Error.Document.AlreadyApplied]', 0;

	declare @stock bit; -- stock journal
	declare @pay bit;   -- pay journal
	declare @acc bit;   -- acc journal
	declare @cash bit;  -- cash journal

	if exists(select * from doc.OpStore 
			where TenantId = @TenantId and Operation = @operation and (IsIn = 1 or IsOut = 1))
		set @stock = 1;
	if exists(select * from doc.OpTrans 
			where TenantId = @TenantId and Operation = @operation)
		set @acc = 1;
	if exists(select * from doc.OpCash 
			where TenantId = @TenantId and Operation = @operation)
		set @cash = 1;

	begin tran;
		exec doc.[Document.Apply.CheckRems] @TenantId= @TenantId, @Id=@Id, @CheckRems = @CheckRems;
		if @stock = 1
			exec doc.[Document.Apply.Stock] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @acc = 1
			exec doc.[Document.Apply.Account] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @cash = 1
			exec doc.[Document.Apply.Cash] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @wsp = 1
			exec doc.[Apply.WriteSupplierPrices] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;
		update doc.Documents set Done = 1, DateApplied = getdate() 
			where TenantId = @TenantId and Id = @Id;
	commit tran;
end
go

