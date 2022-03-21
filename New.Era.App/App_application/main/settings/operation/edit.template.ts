const template: Template = {
	properties: {
		'TRoot.$Tab': String,
		'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]' }
	},
	defaults: {
		"Operation.Group"(this: any) { return this.Params.ParentGroup;}
	},
	validators: {
		'Operation.Name': '@[Error.Required]'
	}
};

export default template;