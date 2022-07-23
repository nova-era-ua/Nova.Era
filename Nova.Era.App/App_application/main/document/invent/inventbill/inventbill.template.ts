
// inventbill
const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRoot.$BrowseStockArg'() { return { IsStock: 'T', PriceKind: this.Document.PriceKind.Id, Date: this.Document.Date }; },
	},
	events: {
	},
	validators: {
	},
	commands: {
	}
};

export default utils.mergeTemplate(base, template);

