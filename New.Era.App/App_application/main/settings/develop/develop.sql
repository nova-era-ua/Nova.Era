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
	delete from doc.DocDetails where TenantId = @TenantId;
	delete from doc.Documents where TenantId = @TenantId;
	delete from cat.ItemRoleAccounts where TenantId = @TenantId;
	delete from cat.Items where TenantId = @TenantId;
	delete from cat.ItemRoles where TenantId = @TenantId;
	delete from cat.ItemTreeElems where TenantId = @TenantId;
	delete from doc.OpTrans where TenantId = @TenantId;
	delete from ui.OpMenuLinks where TenantId = @TenantId;
	delete from doc.Operations where TenantId = @TenantId;
	delete from acc.AccKinds where TenantId = @TenantId;
	delete from acc.Accounts where TenantId = @TenantId;
	commit tran;

	insert into cat.ItemRoles (TenantId, Id, [Name], Color)
	values 
		(@TenantId, 50, N'Товар', N'green'),
		(@TenantId, 51, N'Послуга', N'cyan');

	insert into acc.Accounts(TenantId, Id, [Plan], Parent, IsFolder, Code, [Name], 
		IsItem, IsAgent, IsWarehouse, IsBankAccount, IsCash, IsContract)
	values
		(@TenantId,  10, null, null, 1, N'УПР', N'Управлінський', null, null, null, null, null, null),
		(@TenantId, 281,   10,   10, 0, N'281', N'Товари',          1, 0, 1, 0, 0, 0),
		(@TenantId, 361,   10,   10, 0, N'361', N'Покупці',         0, 1, 0, 0, 0, 1),
		(@TenantId, 631,   10,   10, 0, N'631', N'Постачальники',   0, 1, 0, 0, 0, 1),
		(@TenantId, 301,   10,   10, 0, N'301', N'Каса',            0, 0, 0, 0, 1, 0),
		(@TenantId, 311,   10,   10, 0, N'311', N'Рахунки в банку', 0, 0, 0, 1, 0, 0),
		(@TenantId, 702,   10,   10, 0, N'702', N'Доходи',          0, 0, 0, 0, 0, 0),
		(@TenantId, 902,   10,   10, 0, N'902', N'Собівартість',    0, 0, 0, 0, 0, 0),
		(@TenantId,  91,   10,   10, 0, N'91',  N'Витрати',         0, 0, 0, 0, 0, 0);

	insert into acc.AccKinds(TenantId, Id, [Name])
	values 
		(@TenantId, 70, N'Облік'),
		(@TenantId, 71, N'Дохід'),
		(@TenantId, 72, N'Собівартість');

	insert into cat.ItemRoleAccounts (TenantId, Id, [Plan], [Role], Account, AccKind)
	values
		-- Товари
		(@TenantId, 10, 10, 50, 281, 70),
		(@TenantId, 11, 10, 50, 702, 71),
		(@TenantId, 12, 10, 50, 902, 72),
		-- Послуги
		(@TenantId, 20, 10, 51, 91,  70);

	insert into cat.Items(TenantId, Id, [Name], [Role]) 
	values
		(@TenantId, 20, N'Товар №1', 50),
		(@TenantId, 21, N'Послуга №1', 51);

	insert into doc.Operations (TenantId, Id, [Name], [Form]) values
		(@TenantId, 100, N'Покупка товарів/послуг',			N'waybillin'),
		(@TenantId, 101, N'Оплата постачальнику (банк)',	N'payout'),
		(@TenantId, 102, N'Оплата постачальнику (готівка)',	N'cashout'),
		(@TenantId, 103, N'Продаж товарів/послуг',			N'waybillout'),
		(@TenantId, 104, N'Оплата від покупця (банк)',		N'payin'),
		(@TenantId, 105, N'Оплата від покупця (готівка)',	N'cashin');

	insert into doc.OpTrans(TenantId, Id, Operation, RowNo, RowKind, [Plan], Dt, Ct, 
		[DtSum], DtRow, DtAccMode, DtAccKind,  [CtSum], [CtRow], CtAccMode, CtAccKind)
	values
		(@TenantId, 106, 104, 1, N'',      10,  311,  361,   null, null, null, null,   null, null, null, null),
		(@TenantId, 107, 102, 1, N'',      10,  631,  301,   null, null, null, null,   null, null, null, null),
		(@TenantId, 108, 101, 1, N'',      10,  631,  311,   null, null, null, null,   null, null, null, null),
		(@TenantId, 109, 100, 1, N'All',   10, null,  631,   null, N'R', N'R',   70,   null, null, null, null),
		(@TenantId, 110, 105, 1, N'',      10,  301,  361,   null, null, null, null,   null, null, null, null),
		(@TenantId, 111, 103, 1, N'Stock', 10,  361,  702,   null, null, null, null,   null, null, null, null),
		(@TenantId, 112, 103, 2, N'Stock', 10,  902, null,   N'S', null, null, null,   N'S', N'R', N'R', 70);

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

--exec debug.[TestEnvironment.Create] 1, 99

