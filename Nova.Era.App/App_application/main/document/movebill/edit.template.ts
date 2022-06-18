// movebill

const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRoot.$CheckRems'() { return !this.Document.Done && this.Params.CheckRems; },
		'TRoot.$ItemRolesStock'() { return this.ItemRoles.filter(r => r.IsStock); },
		'TRoot.$BrowseStockArg'() { return { IsStock: 'T', Date: this.Document.Date, CheckRems: this.$CheckRems, Wh: this.Document.WhFrom.Id }; },
	},
	defaults: {
		'Document.WhFrom'(this: any) { return this.Default.Warehouse; },
	},
	validators: {
		'Document.Agent': null,
		'Document.WhTo': '@[Error.Required]',
		'Document.WhFrom': '@[Error.Required]',
		'Document.StockRows[].Qty': [
			'@[Error.Required]',
			{ valid: checkRems, applyIf: checkRemsApply, msg: '@[Error.InsufficientAmount]' }
		]
	},
	events: {
		'Document.Date.change': dateChange,
		'Document.StockRows[].Item.change': itemChange,
		'Document.WhFrom.change': whFromChange,
		'Document.StockRows[].ItemRole.change': itemRoleChange
	},
	commands:{
		reloadRems
	}
};

export default utils.mergeTemplate(base, template);

// #region validators
function checkRems(elem, val): boolean {
	return elem.Qty <= elem.Rem;
}

function checkRemsApply(elem, val): boolean {
	return elem.$root.$CheckRems;
}

// #endregion

// #region events
function itemChange(row, val) {
	base.events['Document.StockRows[].Item.change'].call(this, row, val);
	row.Price = val.Price;
	row.ItemRoleTo = val.Role;
	if (utils.isDefined(val.Rem)) {
		row.Rem = val.Rem;
	}
}

async function dateChange(doc) {
	if (!this.$CheckRems) return;
	if (doc.StockRows.$isEmpty) return;

	const ctrl: IController = this.$ctrl;
	/*
	if (!await ctrl.$confirm('Дата документу змінилася.\nОновити залишки в документі?'))
		return;
	*/
	remChange.call(this, doc);
}

async function whFromChange(doc) {
	if (!this.$CheckRems) return;
	if (doc.StockRows.$isEmpty) return;
	const ctrl: IController = this.$ctrl;
	/*
	if (!await ctrl.$confirm('Склад змінився. Оновити залишки в документі?'))
		return;
	*/
	remChange.call(this, doc);
}

async function itemRoleChange(row, role) {
	if (!this.$CheckRems) return;
	const ctrl: IController = this.$ctrl;
	let doc = this.Document;
	let result = await ctrl.$invoke('getItemRoleRem', { Item: row.Item.Id, Role: role.Id, Date: doc.Date, Wh: doc.WhFrom.Id })
	row.Rem = result?.Result?.Rem || 0;
}


// #endregion

// #region commands
function reloadRems() {
	remChange.call(this, this.Document);
}
// #endregion

async function remChange(doc) {
	const ctrl: IController = this.$ctrl;
	let stocks = doc.StockRows.map(r => r.Item.Id);
	let services = doc.ServiceRows.map(r => r.Item.Id);
	let items = stocks.concat(services).join(',');
	let result = await ctrl.$invoke('getRems', { Items: items, Date: doc.Date, Wh: doc.WhFrom.Id });

	// rems
	doc.StockRows.forEach(row => {
		let rem = result.Rems.find(p => p.Item === row.Item.Id && p.Role == row.ItemRole.Id);
		row.Rem = rem?.Rem || 0;
	});
}


