
const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]' },
		'TOpTrans.$PlanArg'() { return { Plan: this.Plan.Id }; },
		'TOpTrans.$DtAccVisible'() { return this.Plan.Id && this.DtAccMode === ''; },
		'TOpTrans.$CtAccVisible'() { return this.Plan.Id && this.CtAccMode === ''; },
		'TOpTrans.$DtRoleVisible'() { return this.Plan.Id && (this.DtAccMode !== ''); },
		'TOpTrans.$CtRoleVisible'() { return this.Plan.Id && (this.CtAccMode !== ''); },
		'TOpLink.$Types': opLinkTypes
	},
	validators: {
		'Operation.Form': '@[Error.Required]',
		'Operation.Name': '@[Error.Required]',
		'Operation.OpLinks[].Operation': '@[Error.Required]',
		'Operation.OpLinks[].Category': '@[Error.Required]',
		'Operation.Trans[].Plan': '@[Error.Required]'
	},
	events: {
		'Operation.Form.change': formChange,
		'Operation.Trans[].DtAccMode.change'(elem) { elem.Dt.$empty(); },
		'Operation.Trans[].CtAccMode.change'(elem) { elem.Ct.$empty(); },
		'Operation.OpLinks[].add'(links, link) { link.Type = 'BySum';}
	}
};

export default template;

function formChange() {
	// todo: reset all row kinds
}

function opLinkTypes() {
	return [
		{ Name: 'По сумі', Value: 'BySum' },
		{ Name: 'По рядках', Value: 'ByRows' }
	];
}