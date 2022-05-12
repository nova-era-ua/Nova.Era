// waybill in

import { TRoot } from "../_common/stock";

const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
	},
	defaults: {
		'Document.WhTo'(this: any) { return this.Default.Warehouse; },
		'Document.Extra.WriteSupplierPrices': true
	},
	validators: {
		'Document.WhTo': '@[Error.Required]'
	},
	events: {
		'Document.ServiceRows[].Item.change': itemChange,
		'Document.ServiceRows[].ItemRole.change': itemRoleChange
	},
	commands: {
		distributeBySum
	}
};

export default utils.mergeTemplate(base, template);

// events
function itemChange(row, val) {
	base.events['Document.ServiceRows[].Item.change'].call(this, row, val);
	row.CostItem = val.Role.CostItem;
}

function itemRoleChange(row, val) {
	row.CostItem = val.CostItem;
}

function distributeBySum(this: TRoot) {
	if (!this.Document.Extra.IncludeServiceInCost) return;
	let svcSum = this.Document.$ServiceSum;
	let stockSum = this.Document.$StockSum;
	if (!svcSum || !stockSum) return;
	let k = svcSum / stockSum;
	this.Document.StockRows.forEach(row => row.ESum = utils.currency.round(row.Sum * k, 2));
}