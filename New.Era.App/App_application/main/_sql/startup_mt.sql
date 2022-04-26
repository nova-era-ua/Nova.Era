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