-- security schema (catalog)
------------------------------------------------
create or alter procedure appsec.CreateUser
@UserName nvarchar(255),
@PasswordHash nvarchar(max) = null,
@SecurityStamp nvarchar(max),
@Email nvarchar(255) = null,
@PhoneNumber nvarchar(255) = null,
@Tenant int = null,
@PersonName nvarchar(255) = null,
@RegisterHost nvarchar(255) = null,
@Memo nvarchar(255) = null,
@TariffPlan nvarchar(255) = null,
@Locale nvarchar(255) = null,
@RetId bigint output
as
begin
	-- from account/register only
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	set @Locale = isnull(@Locale, N'uk-UA')

	declare @userId bigint; 

	declare @tenants table(id int);
	declare @users table(id bigint);
	declare @tenantId int;

	begin tran;
	insert into appsec.Tenants([Admin], Locale)
		output inserted.Id into @tenants(id)
	values (null, @Locale);

	select top(1) @tenantId = id from @tenants;

	insert into appsec.ViewUsers(UserName, PasswordHash, SecurityStamp, Email, PhoneNumber, Tenant, PersonName, 
		RegisterHost, Memo, Segment, Locale)
		output inserted.Id into @users(id)
		values (@UserName, @PasswordHash, @SecurityStamp, @Email, @PhoneNumber, @tenantId, @PersonName, 
			@RegisterHost, @Memo, a2security.fn_GetCurrentSegment(), @Locale);
	select top(1) @userId = id from @users;

	update appsec.Tenants set [Admin] = @userId where Id=@tenantId;

	commit tran;
	set @RetId = @userId;
end
go
------------------------------------------------
create or alter procedure appsec.ConfirmEmail
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	update appsec.ViewUsers set EmailConfirmed = 1 where Id=@Id;
end
go
------------------------------------------------
create or alter procedure appsec.[User.CheckRegister]
@UserName nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @Id bigint;

	select @Id = Id from appsec.Users where UserName = @UserName and EmailConfirmed = 0 and PhoneNumberConfirmed = 0;

	if @Id is not null
	begin
		declare @uid nvarchar(255);
		set @uid = N'_' + convert(nvarchar(255), newid());
		update appsec.Users set Void=1, UserName = UserName + @uid, 
			Email = Email + @uid, PhoneNumber = PhoneNumber + @uid, PasswordHash = null, SecurityStamp = N''
		where Id=@Id and EmailConfirmed = 0  and PhoneNumberConfirmed = 0 and UserName=@UserName;
	end
end
go
