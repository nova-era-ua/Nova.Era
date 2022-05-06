// waybill in

const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	defaults: {
		'Document.WhTo'(this: any) { return this.Default.Warehouse; }
	},
	validators: {
		'Document.WhTo': '@[Error.Required]'
	},
	events: {
		'Document.ServiceRows[].Item.change': itemChange,
	}
};

export default utils.mergeTemplate(base, template);

// events
function itemChange(row, val) {
	base.events['Document.ServiceRows[].Item.change'].call(this, row, val);
	row.CostItem = val.CostItem;
}
