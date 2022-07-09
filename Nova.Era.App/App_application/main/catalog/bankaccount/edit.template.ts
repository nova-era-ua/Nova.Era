
const template: Template = {
	properties: {
		'TBankAccount.$Id'() { return this.Id || '@[NewItem]' }
	},
	defaults: {
		'BankAccount.Currency'(this: any) { return this.Params.Currency; },
		'BankAccount.Company'(this: any) { return this.Default.Company; },
		'BankAccount.ItemRole'(this: any) { return this.ItemRoles[0]; }
	},
	validators: {
		'BankAccount.AccountNo': '@[Error.Required]',
		'BankAccount.Company': '@[Error.Required]',
		'BankAccount.Currency': '@[Error.Required]'
	},
	events: {
		'BankAccount.AccountNo.change': bankAccountChange
	}
};

export default template;

function bankAccountChange(ba, accno) {
	console.dir(accno);
}