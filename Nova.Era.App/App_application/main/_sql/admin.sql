/*
admin
*/
------------------------------------------------
if not exists(select * from appsec.Tenants where Id <> 0)
begin
	set nocount on;

	insert into appsec.Tenants(Id) values (1);
end
go
------------------------------------------------
if not exists(select * from appsec.Tenants where Id = 0)
begin
	set nocount on;

	insert into appsec.Tenants(Id) values (0);
end
go
------------------------------------------------
if not exists(select * from appsec.Users where Id <> 0)
begin
	set nocount on;
	set transaction isolation level read committed;

	insert into appsec.Users(Id, Tenant, UserName, SecurityStamp, PasswordHash, PersonName, EmailConfirmed)
	values (99, 1, N'admin@admin.com', N'c9bb451a-9d2b-4b26-9499-2d7d408ce54e', N'AJcfzvC7DCiRrfPmbVoigR7J8fHoK/xdtcWwahHDYJfKSKSWwX5pu9ChtxmE7Rs4Vg==',
		N'System administrator', 1);
end
go
