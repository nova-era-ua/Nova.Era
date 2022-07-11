
const template: Template = {
	properties: {
		'TCashAccount.$Id'() { return this.Id || '@[NewItem]' }
		'TCurrency.$Display'() { return this.Short || this.Alpha3; }
	},
	defaults: {
		'CashAccount.Currency'(this:any) { return this.Params.Currency;},
		'CashAccount.Company'(this: any) { return this.Default.Company; },
		'CashAccount.ItemRole'(this: any) { return this.ItemRoles[0]; }
	},
	validators: {
		'CashAccount.Name': '@[Error.Required]',
		'CashAccount.Company': '@[Error.Required]',
		'CashAccount.Currency': '@[Error.Required]'
	}
};

export default template;