
const template: Template = {
	properties: {
		'TWarehouse.$Id'() { return this.Id || '@[NewItem]' }
	},
	validators: {
		'Warehouse.Name': '@[Error.Required]'
	} 
};

export default template;