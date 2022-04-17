// waybill in

const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	defaults: {
		'Document.WhTo'(this: any) { return this.Default.Warehouse; }
	},
	validators: {
		'Document.WhTo': '@[Error.Required]'
	}
};

export default utils.mergeTemplate(base, template);

