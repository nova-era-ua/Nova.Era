// waybill in

import { TRoot, TDocument, TDocExtra } from "../_common/stock";

const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRoot.$ItemRolesSvc'() { return this.ItemRoles.filter(r => r.Kind === 'Item' && !r.IsStock); },
		'TRoot.$ItemRolesStock'() { return this.ItemRoles.filter(r => r.Kind === 'Item' && r.IsStock); },
		'TRoot.$IsStockArg'() { return { IsStock: 'T' }; },
		'TRoot.$IsNoStockArg'() { return { IsStock: 'V' }; }
	},
	defaults: {
		'Document.WhTo'(this: any) { return this.Default.Warehouse; },
		'Document.Extra.WriteSupplierPrices': true
	},
	validators: {
		'Document.WhTo': '@[Error.Required]',
		'Document.$StockESum': validStockESum
	},
	events: {
		'Document.ServiceRows[].Item.change': itemChange,
		'Document.ServiceRows[].ItemRole.change': itemRoleChange,
		'Document.Extra.IncludeServiceInCost.change': flagIncludeChange
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
	let stockRows = this.Document.StockRows;
	let svcSum = this.Document.$ServiceSum;
	let stockSum = this.Document.$StockSum;
	if (!svcSum || !stockSum) return;
	let k = svcSum / stockSum;
	stockRows.forEach(row => row.ESum = utils.currency.round(row.Sum * k, 2));

	// fit last value
	let total = stockRows.reduce((p, c) => p + c.ESum, 0);
	if (total != svcSum) {
		let count = stockRows.length;
		if (count < 2)
			return;
		let sumM1 = stockRows.reduce((p, c, ix) => p + (ix === count - 1 ? 0 : c.ESum), 0);
		stockRows[count - 1].ESum = svcSum - sumM1;
	}
}

function validStockESum(doc: TDocument) {
	if (!doc.Extra.IncludeServiceInCost) return true;
	if (doc.$StockESum !== doc.$ServiceSum)
		return 'Сума націнки не співпадає з сумою послуг';
	return true;
}

function flagIncludeChange(this: TRoot, extra: TDocExtra, val: boolean) {
	if (!val)
		this.Document.StockRows.forEach(row => row.ESum = 0);
}