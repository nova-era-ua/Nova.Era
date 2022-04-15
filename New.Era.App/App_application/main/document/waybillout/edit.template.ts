
const base: Template = require('/document/_common/stock.module');
const tmlutils = require("std:tmlutils");

// waybill out
const template: Template = {
	defaults: {
		'Document.WhFrom'(this: any) { return this.Default.Warehouse; }
	},
	validators: {
		'Document.WhFrom': '@[Error.Required]'
	}
};

export default tmlutils.mergeTemplate(base, template);


