
const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

// waybill out
const template: Template = {
	defaults: {
		'Document.WhFrom'(this: any) { return this.Default.Warehouse; }
	},
	validators: {
		'Document.WhFrom': '@[Error.Required]'
	}
};

export default utils.mergeTemplate(base, template);


