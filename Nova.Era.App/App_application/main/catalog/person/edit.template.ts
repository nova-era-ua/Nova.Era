
const template: Template = {
	properties: {
		'TPerson.$Id'() {return this.Id || '@[NewItem]'}
	},
	validators: {
		'Person.Name': '@[Error.Required]'
	}
};

export default template;