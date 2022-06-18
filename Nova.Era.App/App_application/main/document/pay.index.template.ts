// document pay index

const base: Template = require("document/_common/index.module");
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TCashAccount.$Name'() { return this.Name || this.AccountNo;},
		'TDocument.$CashAccount'() { return this.CashAccFrom?.Id ? this.CashAccFrom?.$Name : this.CashAccTo?.$Name; }
	}
};

export default utils.mergeTemplate(base, template);

