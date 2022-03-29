const template: Template = {
	properties: {
		'TRoot.$Tab': String,
		'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]' }
	},
	defaults: {
		"Operation.Menu"(this: any) { return this.Params.ParentMenu;}
	},
	validators: {
		'Operation.Form': '@[Error.Required]',
		'Operation.Name': '@[Error.Required]',
		'Operation.Journals[].Id': '@[Error.Required]'
	}
};

export default template;