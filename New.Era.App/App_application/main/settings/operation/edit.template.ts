const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]' },
		'TOpTrans.$PlanArg'() { return { Plan: this.Plan.Id }; },
		'TOpTrans.$DtAccVisible'() { return this.Plan.Id && this.DtAccMode === ''; },
		'TOpTrans.$CtAccVisible'() { return this.Plan.Id && this.CtAccMode === ''; },
		'TOpTrans.$DtRoleVisible'() { return this.Plan.Id && this.DtAccMode === 'R'; },
		'TOpTrans.$CtRoleVisible'() { return this.Plan.Id && this.CtAccMode === 'R'; },
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
}