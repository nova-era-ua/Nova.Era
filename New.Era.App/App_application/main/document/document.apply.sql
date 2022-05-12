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

	declare @trans table(TrNo int, RowNo int, DtCt smallint, Acc bigint, CorrAcc bigint, [Plan] bigint, 
		Detail bigint, Item bigint, RowMode nchar(1),
		Wh bigint, CashAcc bigint, [Date] date, Agent bigint, Company bigint, CostItem bigint,
		[Contract] bigint, CashFlowItem bigint, RespCenter bigint,
		Qty float, [Sum] money, ESum money, SumMode nchar(1), CostSum money, [ResultSum] money);

	-- DOCUMENT with ROWS
	with TR as (
		select Dt = case ot.DtAccMode when N'R' then ird.Account else ot.Dt end,
			Ct = case ot.CtAccMode when N'R' then irc.Account else ot.Ct end,
			TrNo = ot.RowNo, dd.[RowNo], Detail = dd.Id, dd.[Item], Qty, dd.[Sum], dd.ESum,
			[Plan] = ot.[Plan], DtRow = isnull(ot.DtRow, N''), CtRow = isnull(ot.CtRow, N''),
			DtSum = isnull(ot.DtSum, N''), CtSum = isnull(ot.CtSum, N''),
			d.[Date], d.Agent, d.Company, d.RespCenter, dd.CostItem, d.WhFrom, d.WhTo, d.CashAccFrom, d.CashAccTo,
			d.[Contract], d.[CashFlowItem]
		from doc.DocDetails dd
			inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
			inner join doc.OpTrans ot on dd.TenantId = ot.TenantId and (dd.Kind = ot.RowKind or ot.RowKind = N'All')
			left join cat.ItemRoleAccounts ird on ird.TenantId = dd.TenantId and ird.[Role] = dd.ItemRole and ird.AccKind = ot.DtAccKind
			left join cat.ItemRoleAccounts irc on irc.TenantId = dd.TenantId and irc.[Role] = dd.ItemRole and irc.AccKind = ot.CtAccKind
		where dd.TenantId = @TenantId and dd.Document = @Id and ot.Operation = @Operation 
			--and (ot.DtRow = N'R' or ot.CtRow = N'R')
	)
	insert into @trans(TrNo, RowNo, DtCt, Acc, CorrAcc, [Plan], [Detail], Item, RowMode, Wh, CashAcc, 
		[Date], Agent, Company, RespCenter, CostItem, [Contract],  CashFlowItem, Qty,[Sum], ESum, SumMode, CostSum, ResultSum)
	select TrNo, RowNo, DtCt = 1, Acc = Dt, CorrAcc = Ct, [Plan], Detail, Item, RowMode = DtRow, Wh = WhTo, CashAcc = CashAccTo,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, [Qty], [Sum], ESum, SumMode = DtSum, CostSum = 0, ResultSum = [Sum]
		from TR
	union all 
	select TrNo, RowNo, DtCt = -1, Acc = Ct, CorrAcc = Dt, [Plan], Detail, Item, RowMode = CtRow, Wh = WhFrom, CashAcc = CashAccFrom,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, [Qty], [Sum], ESum, SumMode = CtSum, CostSum = 0, ResultSum = [Sum]
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
		end

	insert into jrn.Journal(TenantId, Document, Detail, TrNo, RowNo, [Date], DtCt, [Plan], Account, CorrAccount, [Sum], [Qty], [Item],
		Company, Agent, Warehouse, CashAccount, [Contract], CashFlowItem, CostItem, RespCenter)
	select TenantId = @TenantId, Document = @Id, Detail = iif(RowMode = N'R', Detail, null), TrNo, RowNo = iif(RowMode = N'R', RowNo, null),
		[Date], DtCt, [Plan], Acc, CorrAcc, [Sum] = sum([ResultSum]), Qty = sum(iif(RowMode = N'R', Qty, null)),
		Item = iif(RowMode = N'R', Item, null),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter
	from @trans
	group by TrNo, 
		iif(RowMode = N'R', RowNo, null),
		[Date], DtCt, [Plan], Acc, CorrAcc, 
		iif(RowMode = N'R', Item, null),
		iif(RowMode = N'R', Detail, null),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter
	having sum(ResultSum) <> 0 or sum(iif(RowMode = N'R', Qty, null)) is not null;
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
		[Contract] bigint, CashFlowItem bigint, [Sum] money);

	with TR as (
		select Dt = ot.Dt,
			Ct = ot.Ct,
			TrNo = ot.RowNo, d.[Sum],
			[Plan] = ot.[Plan], DtRow = isnull(ot.DtRow, N''), CtRow = isnull(ot.CtRow, N''),
			d.[Date], d.Agent, d.Company, d.RespCenter, d.CostItem, d.WhFrom, d.WhTo, d.CashAccFrom, d.CashAccTo,
			d.[Contract], d.CashFlowItem
		from doc.Documents d
			inner join doc.OpTrans ot on d.TenantId = ot.TenantId and ot.RowKind = N''
		where d.TenantId = @TenantId and d.Id = @Id and ot.Operation = @Operation
	)
	insert into @trans
	select TrNo, DtCt = 1, Acc = Dt, CorrAcc = Ct, [Plan], RowMode = DtRow, Wh = WhTo, CashAcc = CashAccTo,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, [Sum]
		from TR
	union all 
	select TrNo, DtCt = -1, Acc = Ct, CorrAcc = Dt, [Plan], RowMode = CtRow, Wh = WhFrom, CashAcc = CashAccFrom,
		[Date], Agent, Company, RespCenter, CostItem, [Contract], CashFlowItem, [Sum]
		from TR;

	insert into jrn.Journal(TenantId, Document, TrNo, [Date], DtCt, [Plan], Account, CorrAccount, [Sum],
		Company, Agent, Warehouse, CashAccount, [Contract], CashFlowItem, CostItem, RespCenter)
	select TenantId = @TenantId, Document = @Id, TrNo,
		[Date], DtCt, [Plan], Acc, CorrAcc, [Sum] = sum([Sum]),
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter
	from @trans
	group by TrNo, [Date], DtCt, [Plan], Acc, CorrAcc, 
		Company, Agent, Wh, CashAcc, [Contract], CashFlowItem, CostItem, RespCenter
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

	declare @journal table(
		Document bigint, Detail bigint, Company bigint, WhFrom bigint, WhTo bigint,
		Item bigint, Qty float, [Sum] money, Kind nchar(4)
	);
	insert into @journal(Document, Detail, Company, WhFrom, WhTo, Item, Qty, [Sum], Kind)
	select d.Id, dd.Id, d.Company, d.WhFrom, d.WhTo, dd.Item, dd.Qty, dd.[Sum], isnull(dd.Kind, N'')
	from doc.DocDetails dd 
		inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
	where d.TenantId = @TenantId and d.Id = @Id;

	-- out
	insert into jrn.StockJournal(TenantId, Dir, Warehouse, Document, Detail, Company, Item, Qty, [Sum])
	select @TenantId, -1, j.WhFrom, j.Document, j.Detail, j.Company, j.Item, j.Qty, 
		j.[Sum] * js.Factor
	from @journal j inner join doc.OpJournalStore js on js.Operation = @Operation and isnull(js.RowKind, N'') = j.Kind
	where js.TenantId = @TenantId and js.Operation = @Operation and js.IsOut = 1;

	-- in
	insert into jrn.StockJournal(TenantId, Dir, Warehouse, Document, Detail, Company, Item, Qty, [Sum])
	select @TenantId, 1, j.WhTo, j.Document, j.Detail, j.Company, j.Item, j.Qty, 
		j.[Sum] * js.Factor
	from @journal j inner join doc.OpJournalStore js on js.Operation = @Operation and isnull(js.RowKind, N'') = j.Kind
	where js.TenantId = @TenantId and js.Operation = @Operation and js.IsIn = 1;
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
@Id bigint
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

	/*
	if exists(select * from doc.OpJournalStore 
			where TenantId = @TenantId and Operation = @operation and (IsIn = 1 or IsOut = 1))
		set @stock = 1;
	*/
	if exists(select * from doc.OpTrans 
			where TenantId = @TenantId and Operation = @operation)
		set @acc = 1;

	begin tran;
		/*
		if @stock = 1
			exec doc.[Document.Apply.Stock] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		*/
		if @acc = 1
			exec doc.[Document.Apply.Account] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		if @wsp = 1
			exec doc.[Apply.WriteSupplierPrices] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;
		update doc.Documents set Done = 1, DateApplied = getdate() 
			where TenantId = @TenantId and Id = @Id;
	commit tran;
end
go

