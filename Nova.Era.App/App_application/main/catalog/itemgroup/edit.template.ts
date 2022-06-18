

const template: Template = {
	properties: {
		'TGroup.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Group.Name': '@[Error.Required]'
	},
	defaults: {
		'Group.ParentGroup'(this: any) { return this.ParentGroup; }
	}
};

export default template;

