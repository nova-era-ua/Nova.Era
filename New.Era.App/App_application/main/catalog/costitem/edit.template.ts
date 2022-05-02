// costitem.template

const template: Template = {
	properties: {
		'TCostItem.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'CostItem.Name': '@[Error.Required]',
	}
};

export default template;
