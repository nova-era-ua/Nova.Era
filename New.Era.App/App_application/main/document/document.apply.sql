/* Document Apply */
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

	-- ensure empty journal
	delete from jrn.Journal where TenantId = @TenantId and Document = @Id;

	declare @tr table([date] datetime, detail bigint, trno int, rowno int, acc bigint, corracc bigint, [plan] bigint,
		dtct smallint, [sum] money, ssum money, qty float, item bigint, comp bigint, agent bigint, wh bigint, 
		ca bigint, _modesum nchar(1), _moderow nchar(1));

	declare @rowno int, @rowkind nvarchar(16), @plan bigint, @dt bigint, @ct bigint, @dtrow nchar(1), @ctrow nchar(1),
		@dtsum nchar(1), @ctsum nchar(1);

	-- todo: temportary source and accounts from other tables

	declare cur cursor local forward_only read_only fast_forward for
		select RowNo, RowKind, [Plan], [Dt], [Ct], 
			isnull(DtRow, N''), isnull(CtRow, N''), isnull(DtSum, N''), isnull(CtSum, N'')
		from doc.OpTrans where TenantId = @TenantId and Operation = @Operation;
	open cur;
	fetch next from cur into @rowno, @rowkind, @plan, @dt, @ct, @dtrow, @ctrow, @dtsum, @ctsum
	while @@fetch_status = 0
	begin
		-- debit
		if @dtrow = N'R'
			insert into @tr(_moderow, _modesum, [date], detail, trno, rowno, dtct, [plan], acc, corracc, item, qty, [sum], comp, agent, wh, ca)
				select @dtrow, @dtsum, d.[Date], dd.Id, @rowno, dd.RowNo, 1, @plan, @dt, @ct, dd.Item, dd.Qty, dd.[Sum], d.Company, d.Agent, d.WhTo,
					d.CashAccTo
				from doc.DocDetails dd inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
				where d.TenantId = @TenantId and d.Id = @Id and @rowkind = isnull(dd.Kind, N'');
		else if @dtrow = N''
			insert into @tr(_moderow, _modesum, [date], trno, dtct, [plan], acc, corracc, [sum], comp, agent, wh, ca)
				select @dtrow, @dtsum, d.[Date], @rowno, 1, @plan, @dt, @ct, d.[Sum], d.Company, d.Agent, d.WhTo,
					d.CashAccTo
				from doc.Documents d where TenantId = @TenantId and Id = @Id;
		-- credit
		if @ctrow = N'R'
			insert into @tr(_moderow, _modesum, [date], detail, trno, rowno, dtct, [plan], acc, corracc, item, qty, [sum], comp, agent, wh, ca)
				select @ctrow, @ctsum, d.[Date], dd.Id, @rowno, dd.RowNo, -1, @plan, @ct, @dt, dd.Item, dd.Qty, dd.[Sum], d.Company, d.Agent, d.WhFrom,
					d.CashAccFrom
				from doc.DocDetails dd inner join doc.Documents d on dd.TenantId = d.TenantId and dd.Document = d.Id
				where d.TenantId = @TenantId and d.Id = @Id and @rowkind = isnull(dd.Kind, N'');
		else if @ctrow = N''
			insert into @tr(_moderow, _modesum, [date], trno, dtct, [plan], acc, corracc, [sum], comp, agent, wh, ca)
				select @ctrow, @ctsum, d.[Date], @rowno, -1, @plan, @ct, @dt, d.[Sum], d.Company, d.Agent, d.WhFrom,
					d.CashAccFrom
				from doc.Documents d where TenantId = @TenantId and Id = @Id;
		fetch next from cur into @rowno, @rowkind, @plan, @dt, @ct, @dtrow, @ctrow, @dtsum, @ctsum
	end
	close cur;
	deallocate cur;

	if exists(select 1 from @tr where _modesum = N'S' and _moderow = 'R') 
	begin
		with W(item, ssum) as (
			select t.item, [sum] = sum(j.[Sum]) / sum(j.Qty)
			from jrn.Journal j 
			  inner join @tr t on j.Item = t.item and j.Account = t.acc and j.DtCt = 1 and j.[Date] <= t.[date]
			where j.TenantId = @TenantId and t._modesum = N'S' and _moderow = 'R'
			group by t.item
		)
		update @tr set [ssum] = W.ssum * t.qty
		from @tr t inner join W on t.item = W.item
		where t._modesum = N'S' and _moderow = 'R'
	end

	if exists(select 1 from @tr where _modesum = N'S' and _moderow = N'')
	begin
		-- total self cost for this transaction
		with W(trno, item, ssum) as (
			select t.trno, j.Item, [sum] = (sum(j.[Sum]) / sum(j.[Qty])) * t.qty
			from jrn.Journal j 
			  inner join @tr t on j.Item = t.item and j.Account = t.acc and j.DtCt = 1 and j.[Date] <= t.[date]
			where j.TenantId = @TenantId and _moderow = 'R'
			group by trno, j.Item, t.qty
		),
		WT(trno, ssum) as (
			select trno, sum(ssum) from W
			group by trno
		)
		update @tr set [ssum] = WT.ssum
		from @tr t inner join WT on t.trno = WT.trno
		where t._modesum = N'S' and t._moderow = N'';
	end

	insert into jrn.Journal(TenantId, Document, Detail, TrNo, RowNo, [Date],  Company, Warehouse, Agent, Item, 
		DtCt, [Plan], Account, CorrAccount, Qty, CashAccount, [Sum])
	select @TenantId, @Id, detail, trno, rowno, [date], comp, wh, agent, item,
		dtct, [plan], acc, corracc, qty, ca,
		isnull(case _modesum
			when N'S' then ssum
			when N'R' then [sum] - ssum
			else [sum]
		end, 0)
	from @tr;
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
create or alter procedure doc.[Document.UnApply]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	begin tran
	delete from jrn.StockJournal where TenantId = @TenantId and Document = @Id;
	delete from jrn.Journal where TenantId = @TenantId and Document = @Id;
	update doc.Documents set Done = 0, DateApplied = null
		where TenantId = @TenantId and Id = @Id;
	commit tran
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
	select @operation = Operation, @done = Done from doc.Documents where TenantId = @TenantId and Id=@Id;
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

	begin tran
		/*
		if @stock = 1
			exec doc.[Document.Apply.Stock] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		*/
		if @acc = 1
			exec doc.[Document.Apply.Account] @TenantId = @TenantId, @UserId=@UserId,
				@Operation = @operation, @Id = @Id;
		update doc.Documents set Done = 1, DateApplied = getdate() 
			where TenantId = @TenantId and Id = @Id;
	commit tran

end
go

