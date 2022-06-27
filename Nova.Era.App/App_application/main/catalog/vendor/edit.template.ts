// vendor.template

const template: Template = {
	properties: {
		'TVendor.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Vendor.Name': '@[Error.Required]',
	}
};

export default template;
