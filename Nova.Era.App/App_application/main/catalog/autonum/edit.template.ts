

const template: Template = {
	properties: {
		'TAutonum.$Id'() { return this.Id || '@[NewItem]' },
	},
	defaults: {
		'Autonum.Period': 'Y',
		'Autonum.Pattern': '{n}'
	},
	validators: {
		'Autonum.Name': '@[Error.Required]',
		'Autonum.Pattern': '@[Error.Required]'
	}
};

export default template;

