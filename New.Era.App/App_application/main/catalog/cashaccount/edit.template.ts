
const template: Template = {
	properties: {
		'TCashAccount.$Id'() { return this.Id || '@[NewItem]' }
	},
	defaults: {
		'CashAccount.Currency'(this:any) { return this.Params.Currency;}
	},
	validators: {
		'CashAccount.Name': '@[Error.Required]',
		'CashAccount.Company': '@[Error.Required]',
		'CashAccount.Currency': '@[Error.Required]'
	}
};

export default template;