// ret from customer (storno!)

const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRoot.$ItemRolesStock'() { return this.ItemRoles.filter(r => r.Kind === 'Item' && r.IsStock); },
		'TRoot.$IsStockArg'() { return { IsStock: 'T' }; },
	},
	defaults: {
		'Document.WhTo'(this: any) { return this.Default.Warehouse; },
	},
	validators: {
		'Document.WhTo': '@[Error.Required]'
	},
};

export default utils.mergeTemplate(base, template);

