// unit.template

const template: Template = {
	properties: {
		'TBank.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Bank.Name': '@[Error.Required]',
	}
};

export default template;
