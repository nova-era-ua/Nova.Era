﻿// CASH IN

const base: Template = require('/document/_common/pay.module');
const utils: Utils = require("std:utils");

const template: Template = {
	validators: {
		'Document.CashAccTo': '@[Error.Required]',
		'Document.CashAccFrom': '@[Error.Required]',
		'Document.Agent': ''
	},
};

export default utils.mergeTemplate(base, template);



