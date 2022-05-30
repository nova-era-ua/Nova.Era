/*
common
*/
------------------------------------------------
create or alter function cat.fn_GetAgentName(@TenantId int, @Id bigint)
returns nvarchar(255)
as
begin
	declare @name nvarchar(255);
	if @Id is not null and @Id <> -1
		select @name = [Name] from cat.Agents where TenantId=@TenantId and Id=@Id;
	return @name;
end
go
------------------------------------------------
create or alter function cat.fn_GetWarehouseName(@TenantId int, @Id bigint)
returns nvarchar(255)
as
begin
	declare @name nvarchar(255);
	if @Id = -1 
		set @name = N'@[Placeholder.AllWarehouses]';
	else if @Id is not null and @Id <> -1
		select @name = [Name] from cat.Warehouses where TenantId=@TenantId and Id=@Id;
	return @name;
end
go
------------------------------------------------
create or alter function cat.fn_GetCompanyName(@TenantId int, @Id bigint)
returns nvarchar(255)
as
begin
	declare @name nvarchar(255);
	if @Id = -1
		set @name = N'@[Placeholder.AllCompanies]';
	else if @Id is not null
		select @name = [Name] from cat.Companies where TenantId=@TenantId and Id=@Id;
	return @name;
end
go
------------------------------------------------
create or alter function cat.fn_GetCashAccountName(@TenantId int, @Id bigint)
returns nvarchar(255)
as
begin
	declare @name nvarchar(255);
	if @Id is not null
		select @name = isnull([Name], AccountNo) from cat.CashAccounts where TenantId=@TenantId and Id=@Id;
	return @name;
end
go
------------------------------------------------
create or alter function a2sys.fn_GetCurrentTenant(@TenantId int)
returns int
as
begin
	set @TenantId = isnull(cast(session_context(N'TenantId') as int), 1);
	return @TenantId;
end
go
------------------------------------------------
create or alter function cat.fn_GetItemBreadcrumbs(@TenantId int, @Id bigint, @sep nvarchar(32) = null)
returns nvarchar(max)
as
begin
	set @sep = isnull(@sep, N' > ');
	declare @path nvarchar(max);
	with T(Id, Parent, [Level]) as (
		select Id, Parent, 0 from cat.ItemTree where TenantId = @TenantId and Id = @Id
		union all 
		select it.Id, it.Parent, [Level] = T.[Level] + 1 
			from T inner join cat.ItemTree it on it.TenantId = @TenantId and it.Id = T.Parent
		where it.Id <> it.[Root] and it.TenantId = @TenantId
	)
	select @path = string_agg([Name], @sep) within group (order by T.[Level] desc)
	from T inner join cat.ItemTree it on it.TenantId = @TenantId and T.Id = it.Id 
	return @path;
end
go
------------------------------------------------
create or alter function rep.fn_MakeRepId2(@Id1 bigint, @Id2 bigint)
returns nvarchar(64)
as
begin
	return cast(@Id1 as nvarchar(31)) + N'_'+ cast(@Id2 as nvarchar(31));
end
go
------------------------------------------------
create or alter function rep.fn_FoldSaldo(@DtCt smallint, @Dt money, @Ct money)
returns money
as
begin
	declare @e money = @Dt - @Ct;
	declare @r money;
	if @DtCt = 1
		set @r = iif(@e < 0, 0, @e);
	else if @DtCt = -1
		set @r = iif(@e < 0, -@e, 0);
	return @r;
end
go
------------------------------------------------
create or alter function doc.fn_getDocumentRems(@CheckRems bit, @TenantId int, @Document bigint)
returns @rems table (Item bigint, Rem float)
as
begin
	if @CheckRems = 0
		return;
	declare @date date;
	declare @wh bigint;
	declare @check nchar(1);
	declare @plan bigint;
	select @check = CheckRems, @plan = AccPlanRems from app.Settings where TenantId = @TenantId;
	select @date = [Date], @wh = WhFrom from doc.Documents where TenantId = @TenantId and Id=@Document;
	if @check = N'A' and @plan is not null
	begin
		declare @accounts table(Id bigint);
		insert into @accounts(Id) 
		select Id from acc.Accounts where TenantId = @TenantId and Void = 0 and IsItem = 1 and IsWarehouse = 1 and [Plan] = @plan;

		insert into @rems(Item, Rem)
		select j.Item, Rem = sum(j.Qty * DtCt)
		from jrn.Journal j inner join doc.DocDetails dd on j.TenantId = dd.TenantId and j.Item = dd.Item
		where j.TenantId = @TenantId and dd.Document = @Document and j.[Date] <= @date and
			j.Account in (select Id from @accounts) and j.Warehouse = @wh
		group by j.Item;
	end
	return;
end
go
------------------------------------------------
create or alter function doc.fn_getItemsRems(@CheckRems bit, @TenantId int, @Items a2sys.[Id.TableType] readonly, @Date date, @Wh bigint)
returns @rems table (Item bigint, Rem float)
as
begin
	if @CheckRems = 0
		return;
	declare @check nchar(1);
	declare @plan bigint;
	select @check = CheckRems, @plan = AccPlanRems from app.Settings where TenantId = @TenantId;
	if @check = N'A' and @plan is not null
	begin
		declare @accounts table(Id bigint);

		insert into @accounts(Id) 
		select Id from acc.Accounts where TenantId = @TenantId and Void = 0 and IsItem = 1 and IsWarehouse = 1 and [Plan] = @plan;

		insert into @rems(Item, Rem)
		select j.Item, Rem = sum(j.Qty * DtCt)
		from jrn.Journal j inner join @Items dd on j.TenantId = @TenantId and j.Item = dd.Id
		where j.TenantId = @TenantId and j.[Date] <= @Date and
			j.Account in (select Id from @accounts) and j.Warehouse = @Wh
		group by j.Item;
	end
	return;
end
go
