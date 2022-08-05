
const template: Template = {
	properties: {
		'TBankAccount.$Id'() { return this.Id || '@[NewItem]' },
		'TCurrency.$Display'() { return this.Short || this.Alpha3; }
	},
	defaults: {
		'BankAccount.Currency'(this: any) { return this.Params.Currency; },
		'BankAccount.Company'(this: any) { return this.Default.Company; },
		'BankAccount.ItemRole'(this: any) { return this.ItemRoles[0]; }
	},
	validators: {
		'BankAccount.AccountNo': ['@[Error.Required]', validBankAcc ],
		'BankAccount.Company': '@[Error.Required]',
		'BankAccount.Currency': '@[Error.Required]'
	},
	events: {
		'BankAccount.AccountNo.change': bankAccountChange
	}
};

export default template;

function validBankAcc(elem, val): string {
	if (elem.AccountNo.length !== 29)
		return '@[Error.BankAccount.Len]';
	var accno = elem.AccountNo.substring(4, 10);
	if (accno !== elem.Bank.BankCode)
		return '@[Error.BankAccount.IBAN]';
}

async function bankAccountChange(ba, accno) {
	// IBAN 
	const ctrl: IController = this.$ctrl;
	if (!accno || accno.length < 10) {
		ba.Bank.$empty();
		return;
	}
	let bankCode = accno.substring(4, 10);
	if (bankCode === ba.Bank.BankCode)
		return;
	let res = await ctrl.$invoke('find', { Code: bankCode }, '/catalog/bank');
	if (res.Bank)
		ba.Bank.$merge(res.Bank);
	else
		ba.Bank.$empty();
}