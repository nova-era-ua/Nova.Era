-- DEBUG
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'debug')
	exec sp_executesql N'create schema debug';
go
------------------------------------------------
grant execute on schema::debug to public;
go
------------------------------------------------
create or alter procedure debug.[TestEnvironment.Create]
@TenantId int = 1,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	begin tran;
	delete from rep.Reports where TenantId = @TenantId;
	delete from jrn.Journal where TenantId = @TenantId;
	delete from jrn.SupplierPrices where TenantId = @TenantId;
	delete from doc.DocDetails where TenantId = @TenantId;
	delete from doc.DocumentExtra where TenantId = @TenantId;
	delete from doc.Documents where TenantId = @TenantId;
	delete from cat.ItemRoleAccounts where TenantId = @TenantId;
	delete from cat.ItemTreeElems where TenantId = @TenantId;
	delete from cat.Items where TenantId = @TenantId;
	delete from cat.CashAccounts where TenantId = @TenantId;
	delete from cat.ItemRoles where TenantId = @TenantId;
	delete from doc.OpTrans where TenantId = @TenantId;
	delete from ui.OpMenuLinks where TenantId = @TenantId;
	delete from doc.OperationLinks where TenantId = @TenantId;
	delete from doc.Operations where TenantId = @TenantId;
	delete from acc.AccKinds where TenantId = @TenantId;
	delete from app.Settings where TenantId = @TenantId;
	delete from acc.Accounts where TenantId = @TenantId;
	commit tran;

	insert into cat.ItemRoles (TenantId, Id, Kind, [Name], Color, IsStock, HasPrice, ExType)
	values 
		(@TenantId, 50, N'Item', N'Товар', N'green', 1, 1, null),
		(@TenantId, 51, N'Item', N'Послуга', N'cyan', 0, 0, null),
		(@TenantId, 61, N'Money', N'Готівка', N'gold', 0, 0, N'C'),
		(@TenantId, 62, N'Money', N'Безготівкові кошти', N'olive', 0, 0, N'B'),
		(@TenantId, 71, N'Expense', N'Адміністративні витрати', N'tan', 0, 0, N'B');

	insert into acc.Accounts(TenantId, Id, [Plan], Parent, IsFolder, Code, [Name], 
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, IsContract, IsRespCenter, IsCostItem)
	values
		(@TenantId,  10, null, null, 1, N'УПР', N'Управлінський', null, null, null, null, null, null, null, null),
		(@TenantId, 281,   10,   10, 0, N'281', N'Товари',          1, 0, 1, 0, 0, 0, 0, 0),
		(@TenantId, 361,   10,   10, 0, N'361', N'Покупці',         0, 1, 0, 0, 0, 1, 0, 0),
		(@TenantId, 631,   10,   10, 0, N'631', N'Постачальники',   0, 1, 0, 0, 0, 1, 0, 0),
		(@TenantId, 301,   10,   10, 0, N'301', N'Каса',            0, 0, 0, 0, 1, 0, 0, 0),
		(@TenantId, 311,   10,   10, 0, N'311', N'Рахунки в банку', 0, 0, 0, 1, 0, 0, 0, 0),
		(@TenantId, 702,   10,   10, 0, N'702', N'Доходи',          0, 0, 0, 0, 0, 0, 1, 1),
		(@TenantId, 791,   10,   10, 0, N'791', N'Фінрезультат',    0, 0, 0, 0, 0, 0, 1, 1),
		(@TenantId, 902,   10,   10, 0, N'902', N'Собівартість',    0, 0, 0, 0, 0, 0, 1, 1),
		(@TenantId,  91,   10,   10, 0, N'91',  N'Витрати',         0, 0, 0, 0, 0, 0, 1, 1);

	insert into acc.AccKinds(TenantId, Id, [Name])
	values 
		(@TenantId, 70, N'Облік'),
		(@TenantId, 71, N'Дохід'),
		(@TenantId, 72, N'Собівартість'),
		(@TenantId, 73, N'Витрати'),
		(@TenantId, 74, N'Фінансовий результат');

	insert into cat.ItemRoleAccounts (TenantId, Id, [Plan], [Role], Account, AccKind)
	values
		-- Товари
		(@TenantId, 10, 10, 50, 281, 70),
		(@TenantId, 11, 10, 50, 702, 71),
		(@TenantId, 12, 10, 50, 902, 72),
		-- Послуги
		(@TenantId, 20, 10, 51, 91,  70),
		(@TenantId, 21, 10, 51, 702, 71),
		-- Гроші
		(@TenantId, 31, 10, 61, 301, 70),
		(@TenantId, 32, 10, 62, 311, 70);

	insert into cat.Items(TenantId, Id, [Name], [Role]) 
	values
		(@TenantId, 20, N'Товар №1', 50),
		(@TenantId, 21, N'Послуга №1', 51);

	insert into doc.Operations (TenantId, Id, [Name], [Form]) values
		(@TenantId, 100, N'Придбання товарів/послуг',		N'waybillin'),
		(@TenantId, 101, N'Оплата постачальнику (банк)',	N'payout'),
		(@TenantId, 102, N'Оплата постачальнику (готівка)',	N'cashout'),
		(@TenantId, 103, N'Продаж товарів/послуг',			N'waybillout'),
		(@TenantId, 104, N'Оплата від покупця (банк)',		N'payin'),
		(@TenantId, 105, N'Оплата від покупця (готівка)',	N'cashin');

	insert into doc.OpTrans(TenantId, Id, Operation, RowNo, RowKind, [Plan], Dt, Ct, 
		[DtSum], DtRow, DtAccMode, DtAccKind,  [CtSum], [CtRow], CtAccMode, CtAccKind)
	values
		(@TenantId, 106, 104, 1, N'',        10,  311,  361,   null, null, null, null,   null, null, null, null),
		(@TenantId, 107, 102, 1, N'',        10,  631,  301,   null, null, null, null,   null, null, null, null),
		(@TenantId, 108, 101, 1, N'',        10,  631,  311,   null, null, null, null,   null, null, null, null),
		(@TenantId, 109, 100, 1, N'Stock',   10, null,  631,   null, N'R', N'R',   70,   null, null, null, null),
		(@TenantId, 110, 100, 2, N'Service', 10, null,  631,   null, N'R', N'R',   70,   null, null, null, null),
		(@TenantId, 111, 100, 3, N'Stock',   10, null,  631,   N'E', N'R', N'R',   70,   N'E', null, null, null),
		(@TenantId, 112, 105, 1, N'',        10,  301,  361,   null, null, null, null,   null, null, null, null),
		(@TenantId, 113, 103, 1, N'Stock',   10,  361,  702,   null, null, null, null,   null, N'R', N'R',   71),
		(@TenantId, 114, 103, 2, N'Stock',   10,  902, null,   N'S', N'R', N'R',   72,   N'S', N'R', N'R',   70),
		(@TenantId, 115, 103, 3, N'Service', 10,  361, null,   null, null, null, null,   null, N'R', N'R',   71);

	insert into ui.OpMenuLinks(TenantId, Operation, Menu) 
	values
		(@TenantId, 100, N'Purchase.Purchase'),
		(@TenantId, 101, N'Accounting.Bank'),
		(@TenantId, 101, N'Purchase.Payment'),
		(@TenantId, 102, N'Accounting.Cash'),
		(@TenantId, 102, N'Purchase.Payment'),
		(@TenantId, 103, N'Sales.Sales'),
		(@TenantId, 104, N'Accounting.Bank'),
		(@TenantId, 104, N'Sales.Payment'),
		(@TenantId, 105, N'Accounting.Cash'),
		(@TenantId, 105, N'Sales.Payment');

	insert into doc.OperationLinks(TenantId, Id, Parent, Operation, Category, [Type]) 
	values 
		(@TenantId, 20, 100, 101, N'Оплата', N'BySum'),
		(@TenantId, 21, 100, 102, N'Оплата', N'BySum'),
		(@TenantId, 30, 103, 104, N'Оплата', N'BySum'),
		(@TenantId, 31, 103, 105, N'Оплата', N'BySum');

	if not exists(select * from cat.CashAccounts where TenantId = @TenantId and Id = 10 and IsCashAccount = 1)
		insert into cat.CashAccounts(TenantId, Id, Company, Currency, [Name], IsCashAccount, ItemRole) values (@TenantId, 10, 10, 980, N'Основна каса', 1, 61);
	if not exists(select * from cat.CashAccounts where TenantId = @TenantId and Id = 11 and IsCashAccount = 0)
		insert into cat.CashAccounts(TenantId, Id, Company, Currency, [Name], AccountNo, IsCashAccount, ItemRole) values (@TenantId, 11, 10, 980, N'Основний рахунок', N'<номер рахунку>', 0, 62);

	if not exists(select * from app.Settings)
		insert into app.Settings(TenantId, CheckRems, AccPlanRems) values (@TenantId, N'A', 10);
	/*
	select * from doc.Operations where TenantId = 1;
	select N'(@TenantId, ' + cast(Operation - 1000 + 100 as nvarchar) + ', N''' +  Menu + N'''),'
	from ui.OpMenuLinks where TenantId = 1;
	*/

	/*
	select ot.Id, Operation, RowNo, RowKind, ot.[Plan], Dt=da.Code, Ct=ca.Code, DtSum, DtRow, CtSum, CtRow
	from doc.OpTrans ot
	inner join acc.Accounts da on ot.Dt = da.Id
	inner join acc.Accounts ca on ot.Ct = ca.Id
	where ot. TenantId = 1
	order by ot.Id
	*/
end
go

exec debug.[TestEnvironment.Create] 1, 99

