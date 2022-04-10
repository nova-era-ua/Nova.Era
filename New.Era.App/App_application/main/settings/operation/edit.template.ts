const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]' },
		'TOpTrans.$PlanArg'() { return { Plan: this.Plan.Id }; },
		'TOpTrans.$DtAccDisabled'() { return !this.Plan.Id || !!this.DtAccMode; }
},
	defaults: {
		"Operation.Menu"(this: any) { return this.Params.ParentMenu; }
	},
	validators: {
		'Operation.Form': '@[Error.Required]',
		'Operation.Name': '@[Error.Required]'
	},
	events: {
		'Operation.Form.change': formChange,
		'Operation.Trans[].DtAccMode.change'(elem) { elem.Dt.$empty(); },
		'Operation.Trans[].CtAccMode.change'(elem) { elem.Ct.$empty(); }
	}
};

export default template;

function formChange() {
	// todo: reset all row kinds
	alert(1);
}