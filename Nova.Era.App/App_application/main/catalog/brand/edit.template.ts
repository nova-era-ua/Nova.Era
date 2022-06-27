// brand.template

const template: Template = {
	properties: {
		'TBrand.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Brand.Name': '@[Error.Required]',
	}
};

export default template;
