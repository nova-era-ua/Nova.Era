
const template: Template = {
	properties: {
		'TCashAccount.$Id'() { return this.Id || '@[NewItem]' }
	},
	defaults: {
		'CashAccount.Currency'(this:any) { return this.Params.Currency;},
		'CashAccount.Company'(this: any) { return this.Default.Company; }
	},
	validators: {
		'CashAccount.Name': '@[Error.Required]',
		'CashAccount.Company': '@[Error.Required]',
		'CashAccount.Currency': '@[Error.Required]'
	}
};

export default template;