
const base: Template = require('/document/_common/pay.module');
const utils: Utils = require("std:utils");

// Pay in
const template: Template = {
	properties: {
		'TCashAccount.$Name'() { return this.Name || this.AccountNo;}
	},
	validators: {
		'Document.CashAccTo': '@[Error.Required]'
	}
};

export default utils.mergeTemplate(base, template);

