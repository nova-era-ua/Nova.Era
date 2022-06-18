
const template: Template = {
	properties: {
		'TAccount.$Title'() { return this.Id ? this.Id : '@[NewItem]' },
	},
	validators: {
		'Account.Code': '@[Error.Required]',
		'Account.Name': '@[Error.Required]'
	}
};

export default template;

