

const template: Template = {
	properties: {
		'TOption.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Option.Name': '@[Error.Required]'
	},
	defaults: {
	}
};

export default template;

