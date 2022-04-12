
const template: Template = {
	properties: {
		'TBankAccount.$Id'() { return this.Id || '@[NewItem]' }
	},
	validators: {
		'BankAccount.Name': '@[Error.Required]'
	} 
};

export default template;