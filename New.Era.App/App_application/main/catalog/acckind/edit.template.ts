

const template: Template = {
	properties: {
		'TAccKind.$Id'() { return this.Id || '@[NewItem]' },
	},
	defaults: {
	},
	validators: {
		'AccKind.Name': '@[Error.Required]'
	}
};

export default template;

