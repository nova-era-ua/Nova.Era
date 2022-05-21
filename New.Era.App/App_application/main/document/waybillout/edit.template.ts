
const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

// waybill out
const template: Template = {
	properties: {
		'TRoot.$BrowseItemArg'() { return { IsStock: 'T', PriceKind: this.Document.PriceKind.Id }; }
	},
	defaults: {
		'Document.WhFrom'(this: any) { return this.Default.Warehouse; }
	},
	validators: {
		'Document.WhFrom': '@[Error.Required]'
	},
	events: {
		'Document.Contract.change': contractChange,
		'Document.StockRows[].Item.change': itemChange,
	}
};

export default utils.mergeTemplate(base, template);

function contractChange(doc, contract) {
	doc.PriceKind.$set(contract.PriceKind);
}

// events
function itemChange(row, val) {
	base.events['Document.StockRows[].Item.change'].call(this, row, val);
	row.Price = val.Price;
}
