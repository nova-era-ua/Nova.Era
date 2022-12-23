/* Account */
-------------------------------------------------
create or alter procedure acc.[Account.Plan.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	
	declare @fr nvarchar(255) = N'%' + @Text + N'%';

	select [Accounts!TAccount!Array] = null, [Id!!Id] = a.Id, a.Code, a.[Name], a.[Plan], a.IsFolder
	from acc.Accounts a where a.[Plan] is null and a.Parent is null and Void = 0 and 
		(a.Code like @fr or a.[Name] like @fr);
end
go

-------------------------------------------------
create or alter procedure acc.[Account.Fetch]
@TenantId int = 1,
@UserId bigint,
@Plan bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	
	declare @fr nvarchar(255) = N'%' + @Text + N'%';

	select [Accounts!TAccount!Array] = null, [Id!!Id] = a.Id, a.Code, a.[Name], a.[Plan], a.IsFolder
	from acc.Accounts a where 
		a.[Plan] = @Plan and Void = 0 and IsFolder = 0 and (a.Code like @fr or a.[Name] like @fr);
end
go
