
const base: Template = require('/document/_common/pay.module');
const tmlutils = require("std:tmlutils");

// Pay in
const template: Template = {
	properties: {
		'TBankAccount.$Name'() { return this.Name || this.AccountNo;}
	},
	validators: {
		'Document.BankAccTo': '@[Error.Required]'
	}
};

export default tmlutils.mergeTemplate(base, template);

