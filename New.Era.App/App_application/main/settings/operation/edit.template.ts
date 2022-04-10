const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]' },
		'TOpTrans.$PlanArg'() { return { Plan: this.Plan.Id };}
	},
	defaults: {
		"Operation.Menu"(this: any) { return this.Params.ParentMenu;}
	},
	validators: {
		'Operation.Form': '@[Error.Required]',
		'Operation.Name': '@[Error.Required]',
		'Operation.Journals[].Id': '@[Error.Required]'
	},
	events: {
		'Operation.Form.change': formChange
	}
};

export default template;

function formChange(op) {
	let rk = (op.Form.RowKinds || '').split(',');
	let jrnStore = rk.map(k => { return { RowKind: k }; });
	//console.dir(jrnStore);
	op.JournalStore.$empty();
	op.JournalStore.$append(jrnStore);
}