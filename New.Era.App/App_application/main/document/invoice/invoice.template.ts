
// invoice
const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRoot.$$Scan': String
	},
	events: {
		'Root.$$Scan.change': scanChange,
		'Document.Contract.change': contractChange,
	},
	validators: {
		'Document.StockRows[].Qty': '@[Error.Required]'
	},
	commands: {
	}
};

export default utils.mergeTemplate(base, template);

function scanChange() {
	alert('scan');
}

function contractChange(doc, contract) {
	doc.PriceKind.$set(contract.PriceKind);
}
