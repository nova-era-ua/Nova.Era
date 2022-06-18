// cashflowitem.template

const template: Template = {
	properties: {
		'TCashFlowItem.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'CashFlowItem.Name': '@[Error.Required]',
	}
};

export default template;
