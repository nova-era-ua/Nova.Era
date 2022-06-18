
const template: Template = {
	properties: {
		'TCompany.$Id'() { return this.Id || '@[NewItem]' }
	},
	validators: {
		'Company.Name': '@[Error.Required]'
	} 
};

export default template;