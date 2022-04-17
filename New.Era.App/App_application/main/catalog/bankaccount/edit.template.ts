
const template: Template = {
	properties: {
		'TBankAccount.$Id'() { return this.Id || '@[NewItem]' }
	},
	defaults: {
		'BankAccount.Currency'(this: any) { return this.Params.Currency; },
		'BankAccount.Company'(this: any) { return this.Default.Company; }
	},
	validators: {
		'BankAccount.AccountNo': '@[Error.Required]',
		'BankAccount.Company': '@[Error.Required]',
		'BankAccount.Currency': '@[Error.Required]'
	}
};

export default template;