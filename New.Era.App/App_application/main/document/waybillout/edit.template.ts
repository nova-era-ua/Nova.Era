
const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

// waybill out
const template: Template = {
	defaults: {
		'Document.WhFrom'(this: any) { return this.Default.Warehouse; }
	},
	validators: {
		'Document.WhFrom': '@[Error.Required]'
	},
	events: {
		'Document.Contract.change': contractChange
	}
};

export default utils.mergeTemplate(base, template);

function contractChange(doc, contract) {
	doc.PriceKind.$set(contract.PriceKind);
}
