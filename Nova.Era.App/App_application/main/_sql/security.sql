-- security schema
------------------------------------------------
create or alter procedure appsec.SetTenantId
@TenantId int
as
begin
	set nocount on;
	update appsec.Tenants set TransactionCount = TransactionCount + 1, LastTransactionDate = getutcdate() where Id = @TenantId;
	exec sp_set_session_context @key=N'TenantId', @value=@TenantId, @read_only=0;
end
go
------------------------------------------------
create or alter procedure appsec.CreateTenantUser
@Id bigint,
@UserName nvarchar(255),
@Tenant int,
@PersonName nvarchar(255),
@RegisterHost nvarchar(255) = null,
@PhoneNumber nvarchar(255) = null,
@Memo nvarchar(255) = null,
@TariffPlan nvarchar(255) = null,
@TenantRoles nvarchar(max) = null,
@Locale nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	if not exists(select * from appsec.Tenants where Id = @Tenant)
	begin
		declare @sql nvarchar(255);
		declare @prms nvarchar(255);

		if exists(select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = N'appsec' and ROUTINE_NAME=N'OnCreateTenant')
		begin
			set @sql = N'appsec.OnCreateTenant @TenantId';
			set @prms = N'@TenantId int';
		end

		begin tran;

		insert into appsec.Tenants(Id, [Admin], Locale) values (@Tenant, @Id, @Locale);

		insert into appsec.Users(Tenant, Id, UserName, PersonName, RegisterHost, PhoneNumber, Memo, Locale, 
				SecurityStamp, PasswordHash) 
			values(@Tenant, @Id, @UserName, @PersonName, @RegisterHost, @PhoneNumber, @Memo, @Locale, 
				N'', N'');
		/* system user */
		insert into appsec.Users(Tenant, Id, UserName, SecurityStamp, PasswordHash) values 
			(@Tenant, 0, N'System_' + cast(@Tenant as nvarchar(16)), N'', N'');

		if @sql is not null
			exec sp_executesql @sql, @prms, @Tenant;

		commit tran;
	end
	else
	begin
		-- add new user to current tenant
		begin tran
		-- inherit RegisterHost, TariffPlan, Locale
		declare @TenantLocale nvarchar(32);

		select @RegisterHost = RegisterHost, @TenantLocale=t.Locale 
		from appsec.Tenants t inner join appsec.Users u on t.[Admin] = u.Id
		where t.Id = @Tenant;

		insert into appsec.Users(Tenant, Id, UserName, PersonName, RegisterHost, PhoneNumber, Memo, Locale, 
				SecurityStamp, PasswordHash) 
			values(@Tenant, @Id, @UserName, @PersonName, @RegisterHost, @PhoneNumber, @Memo, isnull(@Locale, @TenantLocale),
				N'', N'');
		commit tran;
	end
end
go
------------------------------------------------
create or alter procedure appsec.[TenantUser.Simple.Create]
@Id bigint,
@Tenant int,
@UserName nvarchar(255),
@PersonName nvarchar(255),
@PhoneNumber nvarchar(255),
@Email nvarchar(255),
@RegisterHost nvarchar(255),
@Locale nvarchar(255) = null,
@Segment nvarchar(255) = null,
@Memo nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rt table(Id bigint);
	insert into appsec.Users (Id, Tenant, Segment, UserName, PersonName, PhoneNumber, Email, Memo, RegisterHost,
		EmailConfirmed, SecurityStamp, PasswordHash)
	output inserted.Id into @rt(Id)
	values (@Id, @Tenant, @Segment, @UserName, @PersonName, @PhoneNumber, @Email, @Memo, @RegisterHost,
		1, N'', N'');
end
go
