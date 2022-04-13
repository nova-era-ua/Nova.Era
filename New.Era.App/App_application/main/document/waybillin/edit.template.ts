// waybill in

const base: Template = require('/document/_common/stock.module');
const tmlutils = require("std:tmlutils");

const template: Template = tmlutils.mergeTemplate(base, {
	defaults: {
		'Document.WhTo'(this: any) { return this.Default.Warehouse; }
	},
	validators: {
		'Document.WhTo': '@[Error.Required]'
	}
});

console.dir(template);

export default template;

