// movebill

const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRoot.$RevenueItemRoles'() { return this.ItemRoles.filter(r => r.Kind === 'Revenue'); },
		'TRoot.$CheckRems'() { return !this.Document.Done && this.Params.CheckRems; },
		'TRoot.$BrowseStockArg'() { return { IsStock: 'T', Date: this.Document.Date, CheckRems: this.$CheckRems, Wh: this.Document.WhFrom.Id }; },
	},
	defaults: {
		'Document.WhFrom'(this: any) { return this.Default.Warehouse; },
	},
	validators: {
		'Document.Agent': null,
		'Document.WhTo': '@[Error.Required]',
		'Document.ItemRole': '@[Error.Required]',
		'Document.StockRows[].Qty': '@[Error.Required]'
	},
	events: {
		'Document.StockRows[].ItemRole.change': itemRoleChange,
		'Document.ItemRole.change': docItemRoleChange
	},
	commands:{
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

async function itemRoleChange(row, role) {
	row.CostItem = role.CostItem;
}

async function docItemRoleChange(doc, role) {
	doc.StockRows.forEach(row => {
		row.CostItem = role.CostItem;
	});
}

// #endregion

// #region commands
// #endregion


