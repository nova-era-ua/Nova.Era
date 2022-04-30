// pricekind.template

const template: Template = {
	properties: {
		'TPriceKind.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'PriceKind.Name': '@[Error.Required]',
	}
};

export default template;
