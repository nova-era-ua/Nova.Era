// CASH IN

const base: Template = require('/document/_common/pay.module');
const tmlutils = require("std:tmlutils");

const template: Template = {
	validators: {
		'Document.CashAccTo': '@[Error.Required]'
	},
};

export default tmlutils.mergeTemplate(base, template);



