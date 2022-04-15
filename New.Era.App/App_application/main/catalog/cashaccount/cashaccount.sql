/* Cash ACCOUNT*/
------------------------------------------------
create or alter procedure cat.[CashAccount.Index]
@TenantId int = 1,
@UserId bigint,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @ba table(rowno int identity(1, 1), id bigint, comp bigint, 
		crc bigint, rowcnt int);

	declare @fr nvarchar(255);
	set @fr = N'%' + upper(@Fragment) + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	insert into @ba(id, comp, crc, rowcnt)
	select c.Id, c.Company, c.Currency, 
		count(*) over ()
	from cat.CashAccounts c
	where TenantId = @TenantId and (@fr is null or 
		c.[Name] like @fr or c.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then c.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then c.[Id]
			end
		end desc,
		c.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo,
		[Company!TCompany!RefId] = ca.Company,
		[Currency!TCurrency!RefId] = ca.Currency,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.CashAccounts ca on t.id  = ca.Id and ca.TenantId = @TenantId
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

	select [!$System!] = null, [!CashAccounts!Offset] = @Offset, [!CashAccounts!PageSize] = @PageSize, 
		[!CashAccounts!SortOrder] = @Order, [!CashAccounts!SortDir] = @Dir,
		[!CashAccounts.Fragment!Filter] = @Fragment;
end
go
------------------------------------------------
create or alter procedure cat.[CashAccount.Simple.Index]
@TenantId int = 1,
@UserId bigint,
@Company bigint = null,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CashAccounts!TCashAccount!Array] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo
	from cat.CashAccounts ca
	where ca.TenantId = @TenantId and ca.Company = @Company;

	select [Company!TCompany!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Companies where TenantId = @TenantId and Id=@Company;
end
go
------------------------------------------------
create or alter procedure cat.[CashAccount.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [CashAccount!TCashAccount!Object] = null,
		[Id!!Id] = ca.Id, [Name!!Name] = ca.[Name], ca.Memo,
		[Company!TCompany!RefId] = ca.Company,
		[Currency!TCurrency!RefId] = ca.Currency
	from cat.CashAccounts ca
	where TenantId = @TenantId and ca.Id = @Id;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join cat.CashAccounts ca on c.TenantId = ca.TenantId and ca.Company = c.Id
	where c.TenantId = @TenantId and ca.Id = @Id;

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, c.Short
	from cat.Currencies c inner join cat.CashAccounts ca on c.TenantId = ca.TenantId and ca.Currency = c.Id
	where c.TenantId = @TenantId and ca.Id = @Id;

	-- TODO: // BASE Currency!
	select [Params!TParam!Object] = null, [Currency.Id!TCurrency!Id] = c.Id, [Currency.Short!TCurrency!] = c.Short
	from cat.Currencies c where TenantId = @TenantId and c.Id = 980;

end
go
---------------------------------------------
drop procedure if exists cat.[CashAccount.Metadata];
drop procedure if exists cat.[CashAccount.Update];
drop type if exists cat.[CashAccount.TableType];
go
------------------------------------------------
create type cat.[CashAccount.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	Company bigint,
	[Memo] nvarchar(255),
	Currency bigint
)
go
---------------------------------------------
create or alter procedure cat.[CashAccount.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Cash cat.[CashAccount.TableType];
	select [CashAccount!CashAccount!Metadata] = null, * from @Cash;
end
go
---------------------------------------------
create or alter procedure cat.[CashAccount.Update]
@TenantId int = 1,
@UserId bigint,
@CashAccount cat.[CashAccount.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.CashAccounts as t
	using @CashAccount as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Company = s.Company,
		t.Currency = s.Currency
	when not matched by target then insert
		(TenantId, Company, [Name], Currency, Memo) values
		(@TenantId, s.Company, s.[Name], s.Currency, s.Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[CashAccount.Load] @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[CashAccount.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.CashAccounts set Void = 1 where TenantId = @TenantId and Id = @Id;
end
go
