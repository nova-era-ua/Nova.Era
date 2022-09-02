// brand.template

const template: Template = {
	properties: {
		'TProject.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Project.Name': '@[Error.Required]',
	}
};

export default template;
