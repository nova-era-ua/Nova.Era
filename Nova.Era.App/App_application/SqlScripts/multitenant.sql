/*
version: 10.1.1014
generated: 25.07.2022 07:51:30
*/


/* SqlScripts/multitenant.sql */

/*
startup multitenant
*/
-------------------------------------------------
create or alter procedure appsec.OnCreateTenant 
@TenantId int
as
begin
	set nocount on
	exec ini.[Cat.OnCreateTenant] @TenantId = @TenantId;
	exec ini.[Forms.OnCreateTenant] @TenantId = @TenantId;
	exec ini.[Rep.OnCreateTenant] @TenantId = @TenantId;
end
go
-------------------------------------------------
create or alter procedure appsec.OnCreateTenantAll
as
begin
	set nocount on;
	-- ItemTree Root
	merge cat.ItemTree as t
	using (
		select TenantId = t.Id, it.Id from appsec.Tenants t
			left join cat.ItemTree it on t.Id = it.TenantId and it.Id = 0 
		where t.Id > 1
	) as s
	on t.Id = s.Id
	when not matched by target then insert
	(TenantId, Id, [Root], [Parent], [Name]) values
	(TenantId, 0, 0, 0, N'Root');
end
go
-------------------------------------------------
exec appsec.OnCreateTenantAll;
go

--- TEMPORARY
begin
	declare @tenantId int;
	declare t_cursor cursor local fast_forward for
	select Id from appsec.Tenants where Id > 1;
	open t_cursor
	fetch next from t_cursor into @tenantId;
	while @@fetch_status = 0
	begin
		exec appsec.OnCreateTenant @TenantId = @tenantId
		fetch next from t_cursor into @tenantId;
	end
	close t_cursor;
	deallocate t_cursor;
end
go
