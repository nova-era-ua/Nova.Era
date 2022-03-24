
const template: Template = {
	properties: {
		'TAgent.$Title'() {return this.Id || '@[NewItem]'}
	},
	validators: {
		'Agent.Name': '@[Error.Required]'
	}
};

export default template;