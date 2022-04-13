/* BANK ACCOUNT*/
------------------------------------------------
create or alter procedure cat.[BankAccount.Index]
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

	declare @ba table(rowno int identity(1, 1), id bigint, comp bigint, bank bigint, 
		crc bigint, rowcnt int);

	declare @fr nvarchar(255);
	set @fr = N'%' + upper(@Fragment) + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	insert into @ba(id, comp, bank, crc, rowcnt)
	select b.Id, b.Company, b.Bank, b.Currency, 
		count(*) over ()
	from cat.BankAccounts b
	where TenantId = @TenantId and (@fr is null or 
		b.[Name] like @fr or b.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order
				when N'accountno' then b.[AccountNo]
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'accountno' then b.[AccountNo]
				when N'name' then b.[Name]
				when N'memo' then b.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then b.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then b.[Id]
			end
		end desc,
		b.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [BankAccounts!TBankAccount!Array] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo, 
		[Company!TCompany!RefId] = ba.Company,
		[Currency!TCurrency!RefId] = ba.Currency,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.BankAccounts ba on t.id  = ba.Id and ba.TenantId = @TenantId
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

	select [!$System!] = null, [!BankAccounts!Offset] = @Offset, [!BankAccounts!PageSize] = @PageSize, 
		[!BankAccounts!SortOrder] = @Order, [!BankAccounts!SortDir] = @Dir,
		[!BankAccounts.Fragment!Filter] = @Fragment;
end
go
------------------------------------------------
create or alter procedure cat.[BankAccount.Simple.Index]
@TenantId int = 1,
@UserId bigint,
@Company bigint = null,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [BankAccounts!TBankAccount!Array] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo
	from cat.BankAccounts ba
	where ba.TenantId = @TenantId and Company = @Company;

	select [Company!TCompany!Object] = null, [Id!!Id] = Id, [Name!!Name] = [Name]
	from cat.Companies where TenantId = @TenantId and Id=@Company;
end
go
------------------------------------------------
create or alter procedure cat.[BankAccount.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [BankAccount!TBankAccount!Object] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo,
		[Company!TCompany!RefId] = ba.Company,
		[Currency!TCurrency!RefId] = ba.Currency,
		[Bank!TBank!RefId] = ba.Bank
	from cat.BankAccounts ba
	where TenantId = @TenantId and ba.Id = @Id;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join cat.BankAccounts ba on c.TenantId = ba.TenantId and ba.Company = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id;

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, c.Short
	from cat.Currencies c inner join cat.BankAccounts ba on c.TenantId = ba.TenantId and ba.Currency = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id;

	-- TODO: // BASE Currency!
	select [Params!TParam!Object] = null, [Currency.Id!TCurrency!Id] = c.Id, [Currency.Short!TCurrency!] = c.Short
	from cat.Currencies c where TenantId = @TenantId and c.Id = 980;

end
go
---------------------------------------------
drop procedure if exists cat.[BankAccount.Metadata];
drop procedure if exists cat.[BankAccount.Update];
drop type if exists cat.[BankAccount.TableType];
go
------------------------------------------------
create type cat.[BankAccount.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	AccountNo nvarchar(255),
	Company bigint,
	[Memo] nvarchar(255),
	Currency bigint,
	Bank bigint
)
go
---------------------------------------------
create or alter procedure cat.[BankAccount.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Bank cat.[BankAccount.TableType];
	select [BankAccount!BankAccount!Metadata] = null, * from @Bank;
end
go
---------------------------------------------
create or alter procedure cat.[BankAccount.Update]
@TenantId int = 1,
@UserId bigint,
@BankAccount cat.[BankAccount.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge cat.BankAccounts as t
	using @BankAccount as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Company = s.Company,
		t.AccountNo = s.AccountNo,
		t.Currency = s.Currency,
		t.Bank = s.Bank
	when not matched by target then insert
		(TenantId, Company, [Name], AccountNo, Currency, Bank, Memo) values
		(@TenantId, s.Company, s.[Name], s.AccountNo, s.Currency, s.Bank, s.Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[BankAccount.Load] @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[BankAccount.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.BankAccounts set Void = 1 where TenantId = @TenantId and Id = @Id;
end
go
