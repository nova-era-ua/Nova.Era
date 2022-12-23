
const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]' },
		'TOperation.DocumentUrl'() { return `${this.Form.Url}/${this.Form.Id}`; },
		'TOpTrans.$PlanArg'() { return { Plan: this.Plan.Id }; },
		'TOpTrans.$DtAccVisible'() { return this.Plan.Id && this.DtAccMode === ''; },
		'TOpTrans.$CtAccVisible'() { return this.Plan.Id && this.CtAccMode === ''; },
		'TOpTrans.$DtRoleVisible'() { return this.Plan.Id && (this.DtAccMode !== ''); },
		'TOpTrans.$CtRoleVisible'() { return this.Plan.Id && (this.CtAccMode !== ''); },
		'TOpLink.$Types': opLinkTypes,
		'TOpLink.$Categories': opLinkCategories
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
		'Operation.OpLinks[].add'(links, link) { link.Type = 'BySum'; },
		'Operation.Trans[].add': transAdd
	},
	delegates: {
		fetchByPlan
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

function opLinkCategories() {
	return [
		{ Name: 'Відвантаження', Value: 'Shipment' },
		{ Name: 'Оплата', Value: 'Payment' },
		{ Name: 'Повернення', Value: 'Return' },
		{ Name: 'Повернення коштів', Value: 'RetMoney' }
	];
}

function fetchByPlan(acc, text) {
	let ctrl: IController = this.$ctrl;
	return ctrl.$invoke('fetch', { Plan: acc.$parent.Plan.Id, Text: text }, '/catalog/account');
}

function transAdd(arr, elem) {
	let ix = arr.indexOf(elem);
	if (ix < 1) return;
	let prev = arr[ix - 1];
	elem.Plan.$merge(prev.Plan);
}
