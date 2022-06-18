-- reports plan
-------------------------------------------------
create or alter procedure rep.[Report.Turnover.Plan.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company)
		from usr.Defaults where TenantId = @TenantId and UserId = @UserId;
	declare @comp bigint = nullif(@Company, -1);

	declare @acc bigint;
	select @acc = Account from rep.Reports where TenantId = @TenantId and Id = @Id;


	declare @totbl table (account bigint, startsum money, dtsum money, ctsum money, endsum money, grp tinyint);

	insert into @totbl (account, startsum, dtsum, ctsum, endsum, grp)
	select
		j.Account,
		sum(case when j.[Date] < @From then j.[Sum] * j.DtCt else 0 end),
		sum(case when j.[Date] >= @From and j.DtCt = 1 then j.[Sum] else 0 end),
		sum(case when j.[Date] >= @From and j.DtCt = -1 then j.[Sum] else 0 end),
		sum(j.[Sum] * j.DtCt),
		grouping(j.Account)
	from
		jrn.Journal j
	where j.TenantId = @TenantId 
		and (@comp is null or j.Company = @comp)
		and j.[Date] < @end and j.[Plan] = @acc
	group by rollup(j.Account) -- case A.UseAgent when 1 then J.Agent else null end;
	
	select [RepData!TRepData!Group] = null,
		AccCode = a.Code,
		AccName = a.[Name],
		AccId = a.Id,
		DtStart = case when t.startsum > 0 then t.startsum else 0 end,
		CtStart = -(case when t.startsum < 0 then t.startsum else 0 end),
		DtSum =  t.dtsum,
		CtSum = t.ctsum,
		DtEnd = case when t.endsum > 0 then t.endsum else 0 end,
		CtEnd = -case when t.endsum < 0 then t.endsum else 0 end,
		[Account!!GroupMarker] = t.grp,
		[Items!TRepData!Items] = null
	from @totbl t
		left join acc.Accounts a on a.TenantId = @TenantId and a.Id = t.account

	order by t.grp desc, a.Code;

	select [Report!TReport!Object] = null, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @acc;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Plan.Cashflow.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@From date = null,
@To date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	exec usr.[Default.GetUserPeriod] @TenantId = @TenantId, @UserId = @UserId, @From = @From output, @To = @To output;
	declare @end date = dateadd(day, 1, @To);

	select @Company = isnull(@Company, Company)
	from usr.Defaults where TenantId = @TenantId and UserId = @UserId;

	declare @plan bigint;
	select @plan = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @accs table(id int);

	insert into @accs(id)
	select Id
	from acc.Accounts a where TenantId = @TenantId and [Plan] = @plan 
		and IsFolder = 0 and (IsCash = 1 or IsBankAccount = 1)
	group by a.Id;

	with T as (
		select ca.IsCashAccount, 
			j.CashAccount,
			StartSum = sum(case when j.[Date] < @From then j.[Sum] * j.DtCt else 0 end),
			DtSum = sum(case when j.[Date] >= @From and j.DtCt = 1 then j.[Sum] else 0 end),
			CtSum = sum(case when j.[Date] >= @From and j.DtCt = -1 then j.[Sum] else 0 end),
			EndSum = sum(j.[Sum] * j.DtCt),
			GrpGroup = grouping(ca.IsCashAccount),
			GrpAccount = grouping(j.CashAccount)
		from jrn.Journal j
			inner join @accs a on  j.TenantId = @TenantId and j.Account = a.id
			left join cat.CashAccounts ca on ca.TenantId = j.TenantId and j.CashAccount = ca.Id
		where j.TenantId = @TenantId and j.[Date] < @end and j.Company = @Company
		group by rollup(ca.IsCashAccount, j.CashAccount)
	)
	select [RepData!TRepData!Group] = null,
		[GrpName] = 
		case T.IsCashAccount
			when 1 then N'Каса'
			when 0 then N'Рахунки в банках'
			else null
		end,
		[Name] = isnull(ca.[Name], ca.AccountNo),
		[Currency] = c.Short,
		StartSum, DtSum, CtSum, EndSum,
		[GrpName!!GroupMarker] = GrpGroup,
		[Name!!GroupMarker] = GrpAccount,
		[Items!TRepData!Items] = null
	from T
		left join cat.CashAccounts ca on ca.TenantId = @TenantId and ca.Id = T.CashAccount
		left join cat.Currencies c on ca.TenantId = c.TenantId and ca.Currency = c.Id
	order by GrpGroup desc, GrpAccount desc;

	select [Report!TReport!Object] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @plan;

	select [!$System!] = null, 
		[!RepData.Period.From!Filter] = @From, [!RepData.Period.To!Filter] = @To,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
-------------------------------------------------
create or alter procedure rep.[Report.Plan.ItemRems.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint, /* report id */
@Date date = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Date = isnull(@Date, getdate());

	select @Company = isnull(@Company, Company)
		from usr.Defaults where TenantId = @TenantId and UserId = @UserId;
	declare @comp bigint = nullif(@Company, -1);

	declare @plan bigint;
	select @plan = Account from rep.Reports where TenantId = @TenantId and Id = @Id;

	declare @accounts table(Id bigint);
	insert into @accounts(Id) 
		select Id from acc.Accounts where TenantId = @TenantId and [Plan] = @plan and Void = 0 and IsWarehouse = 1 and IsItem = 1;

	select Warehouse, Item,
		Qty = sum(Qty * DtCt)
	into #tmp
	from jrn.Journal 
	where  Account in (select Id from @accounts) and [Plan] = @plan and TenantId = @TenantId
		and [Date] <= @Date and (@comp is null or Company = @comp)
	group by Warehouse, Item

	select [RepData!TRepData!Array] = null, [Id!!Id] = Item,
		[Item!TItem!RefId] = t.Item, Rem = sum(t.Qty),
		[WhCross!TCross!CrossArray] = null
	from #tmp t
	group by Item
	order by Item;

	-- cross part
	select [!TCross!CrossArray] = null, [Wh!!Key] = t.Warehouse, Rem = sum(t.Qty),
		[!TRepData.WhCross!ParentId] = t.Item
	from #tmp t
	group by Item, Warehouse;

	-- report
	select [Report!TReport!Object] = null,  [Id!!Id] = r.Id, [Name!!Name] = r.[Name], [Account!TAccount!RefId] = r.Account
	from rep.Reports r
	where r.TenantId = @TenantId and r.Id = @Id;

	-- maps
	with T as (select Item from #tmp group by Item)
	select [!TItem!Map] = null, i.*
	from cat.view_Items i inner join T on i.[!TenantId] = @TenantId and T.Item = i.[Id!!Id];

	with T as (select Warehouse from #tmp group by Warehouse)
		select [Warehouses!TWarehouse!Array] = null, [Id!!Id] = w.Id,
		[Key!!Key] = cast(w.Id as nvarchar(32)), [Name!!Name] = w.[Name],
		[!TReport.Warehouses!ParentId] = @Id
	from cat.Warehouses w inner join T on w.TenantId = @TenantId and T.Warehouse = w.Id;

	select [!TAccount!Map] = null, [Id!!Id] = Id, [Name!!Name] = [Name], [Code]
	from acc.Accounts where TenantId = @TenantId and Id = @plan;

	-- system
	select [!$System!] = null, 
		[!RepData.Date!Filter] = @Date,
		[!RepData.Company.Id!Filter] = @Company, [!RepData.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company);
end
go
