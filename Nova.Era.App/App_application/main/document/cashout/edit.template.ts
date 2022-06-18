// CASH IN

const base: Template = require('/document/_common/pay.module');
const utils: Utils = require("std:utils");

const template: Template = {
	validators: {
		'Document.CashAccFrom': '@[Error.Required]'
	},
};

export default utils.mergeTemplate(base, template);



