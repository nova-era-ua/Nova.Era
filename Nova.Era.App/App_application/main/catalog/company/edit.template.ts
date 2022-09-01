
const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TCompany.$Id'() { return this.Id || '@[NewItem]' }
	},
	validators: {
		'Company.Name': '@[Error.Required]'
	} 
};

export default template;