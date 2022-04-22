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
