﻿/* BANK ACCOUNT*/
------------------------------------------------
create or alter procedure cat.[BankAccount.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @ba table(rowno int identity(1, 1), id bigint, comp bigint, bank bigint, 
		crc bigint, rowcnt int, balance money);

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	insert into @ba(id, comp, bank, crc, balance, rowcnt)
	select b.Id, b.Company, b.Bank, b.Currency, isnull(cr.[Sum], 0),
		count(*) over ()
	from cat.CashAccounts b
		left join jrn.CashReminders cr on  b.TenantId = cr.TenantId and cr.CashAccount = b.Id
		left join cat.Banks bnk on bnk.TenantId = b.TenantId and bnk.Id = b.Bank
	where b.TenantId = @TenantId and b.IsCashAccount = 0 
		and (@Company is null or b.Company = @Company)
		and (@fr is null or b.[Name] like @fr or b.Memo like @fr or bnk.[Name] like @fr)
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
				when N'balance' then cr.[Sum]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then b.[Id]
				when N'balance' then cr.[Sum]
			end
		end desc,
		b.Id
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [BankAccounts!TBankAccount!Array] = null,
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo, Balance = t.balance,
		[Company!TCompany!RefId] = ba.Company,
		[Currency!TCurrency!RefId] = ba.Currency,
		[ItemRole!TItemRole!RefId] = ba.ItemRole,
		[Bank!TBank!RefId] = ba.Bank,
		[!!RowCount] = t.rowcnt
	from @ba t inner join cat.CashAccounts ba on t.id  = ba.Id and ba.TenantId = @TenantId
	order by t.rowno;

	with T as(select comp from @ba group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join T on c.TenantId = @TenantId and c.Id = T.comp;

	with T as(select crc from @ba group by crc)
	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Alpha3
	from cat.Currencies c inner join T on c.TenantId = @TenantId and c.Id = T.crc;

	with T as(select bank from @ba group by bank)
	select [!TBank!Map] = null, [Id!!Id] = b.Id, [Name!!Name] = b.[Name], b.BankCode
	from cat.Banks b inner join T on b.TenantId = @TenantId and b.Id = T.bank;

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money' and ir.ExType = N'B';

	select [!$System!] = null, [!BankAccounts!Offset] = @Offset, [!BankAccounts!PageSize] = @PageSize, 
		[!BankAccounts!SortOrder] = @Order, [!BankAccounts!SortDir] = @Dir,
		[!BankAccounts.Company.Id!Filter] = @Company, [!BankAccounts.Company.Name!Filter] = cat.fn_GetCompanyName(@TenantId, @Company),
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
		[Id!!Id] = ba.Id, [Name!!Name] = ba.[Name], ba.Memo, ba.AccountNo,
		[ItemRole!TItemRole!RefId] = ba.ItemRole,
		Balance = cr.[Sum]
	from cat.CashAccounts ba
		left join jrn.CashReminders cr on  ba.TenantId = cr.TenantId and cr.CashAccount = ba.Id
	where ba.TenantId = @TenantId and (@Company is null or Company = @Company) and ba.IsCashAccount = 0;

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money' and ir.ExType = N'B';

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
		[Bank!TBank!RefId] = ba.Bank, [ItemRole!TItemRole!RefId] = ba.ItemRole,
		Balance = cr.[Sum]
	from cat.CashAccounts ba
		left join jrn.CashReminders cr on  ba.TenantId = cr.TenantId and cr.CashAccount = ba.Id
	where ba.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c inner join cat.CashAccounts ba on c.TenantId = ba.TenantId and ba.Company = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TCurrency!Map] = null, [Id!!Id] = c.Id, c.Short, c.Alpha3
	from cat.Currencies c inner join cat.CashAccounts ba on c.TenantId = ba.TenantId and ba.Currency = c.Id
	where c.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [!TBank!Map] = null, [Id!!Id] = b.Id, b.BankCode, b.[Name]
	from cat.Banks b inner join cat.CashAccounts ba on b.TenantId = ba.TenantId and ba.Bank = b.Id
	where b.TenantId = @TenantId and ba.Id = @Id and ba.IsCashAccount = 0;

	select [ItemRoles!TItemRole!Map] = null, [Id!!Id] = ir.Id, [Name!!Name] = ir.[Name], ir.IsStock, ir.Kind
	from cat.ItemRoles ir where ir.TenantId = @TenantId and ir.Void = 0 and ir.Kind = N'Money' and ir.ExType = N'B';

	-- TODO: // BASE Currency!
	select [Params!TParam!Object] = null, [Currency.Id!TCurrency!Id] = c.Id, 
		[Currency.Short!TCurrency!] = c.Short, [Currency.Alpha3!TCurrency!] = c.Alpha3
	from cat.Currencies c where TenantId = @TenantId and c.Id = 980;

	exec usr.[Default.Load] @TenantId = @TenantId, @UserId = @UserId;
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
	Bank bigint,
	ItemRole bigint
)
go
---------------------------------------------
create or alter procedure cat.[BankAccount.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @BankAccount cat.[BankAccount.TableType];
	select [BankAccount!BankAccount!Metadata] = null, * from @BankAccount;
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

	merge cat.CashAccounts as t
	using @BankAccount as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.[Memo] = s.[Memo],
		t.Company = s.Company,
		t.AccountNo = s.AccountNo,
		t.Currency = s.Currency,
		t.Bank = s.Bank,
		t.ItemRole = s.ItemRole
	when not matched by target then insert
		(TenantId, IsCashAccount, ItemRole, Company, [Name], AccountNo, Currency, Bank, Memo) values
		(@TenantId, 0, s.ItemRole, s.Company, s.[Name], s.AccountNo, s.Currency, s.Bank, s.Memo)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	exec cat.[BankAccount.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
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

	update cat.CashAccounts set Void = 1 where TenantId = @TenantId and Id = @Id and IsCashAccount = 0;
end
go
