

const template: Template = {
	properties: {
		'TGroup.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Group.Name': '@[Error.Required]'
	}
};

export default template;

