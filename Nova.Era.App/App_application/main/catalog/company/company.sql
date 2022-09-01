-- Company
------------------------------------------------
create or alter procedure cat.[Company.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Companies!TCompany!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo
	from cat.Companies c
	where c.TenantId = @TenantId; 
end
go
------------------------------------------------
create or alter procedure cat.[Company.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Company!TCompany!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], Memo,
		AutonumPrefix,
		[Logo.Id!TImage!Id] = c.Logo, [Logo.Token!TImage!Token] = lb.AccessToken
	from cat.Companies c
		left join app.Blobs lb on c.TenantId = lb.TenantId and c.Logo = lb.Id
	where c.TenantId = @TenantId and c.Id = @Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Company.Logo.Load]
@TenantId int = 1,
@UserId bigint,
@Key nvarchar(255),
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	set @TenantId = isnull(@TenantId, 1); -- required for image

	select Mime, [Stream], [Name], [Token] = AccessToken
	from app.Blobs where TenantId = @TenantId and Id = @Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Company.Logo.Update]
@TenantId int = 1,
@UserId bigint,
@Name nvarchar(255), 
@Mime nvarchar(255),
@Stream varbinary(max),
@BlobName nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	set @TenantId = isnull(@TenantId, 1); -- required for image

	declare @rtable table(id bigint, token uniqueidentifier);
	insert into app.Blobs(TenantId, [Name], Mime, [Stream], BlobName)
		output inserted.Id, inserted.AccessToken into @rtable(id, token)
	values (@TenantId, @Name, @Mime, @Stream, @BlobName);

	select Id = id, Token = token from @rtable;
end
go
-------------------------------------------------
drop procedure if exists cat.[Company.Metadata];
drop procedure if exists cat.[Company.Update];
drop type if exists cat.[Company.TableType];
go
-------------------------------------------------
create type cat.[Company.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	AutonumPrefix nvarchar(8),
	Logo bigint
)
go
------------------------------------------------
create or alter procedure cat.[Company.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Company cat.[Company.TableType];
	select [Company!Company!Metadata] = null, * from @Company;
end
go
------------------------------------------------
create or alter procedure cat.[Company.Update]
@TenantId int = 1,
@UserId bigint,
@Company cat.[Company.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Companies as t
	using @Company as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[FullName] = s.[FullName],
		t.AutonumPrefix = s.AutonumPrefix,
		t.Logo = s.Logo
	when not matched by target then insert
		(TenantId, [Name], FullName, Memo, AutonumPrefix, Logo) values
		(@TenantId, s.[Name], s.FullName, s.Memo, s.AutonumPrefix, Logo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Company.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[Company.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Companies!TCompany!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo, c.FullName
	from cat.Companies c
	where TenantId = @TenantId and Void = 0 and
		([Name] like @fr or Memo like @fr or FullName like @fr)
	order by c.[Name];
end
go
