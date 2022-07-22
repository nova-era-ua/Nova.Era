// document pay index

const base: Template = require("document/_common/index.module");
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
		'TDocument.$SumDir': sumDir,
		'TDocument.$CashAccount': cashAccountText
	}
};

export default utils.mergeTemplate(base, template);

function cashAccountText() {
	if (this.CashAccFrom?.Id && this.CashAccTo?.Id)
		return `${this.CashAccFrom.$Name} -> ${this.CashAccTo.$Name}`;
	return this.CashAccFrom?.Id ? this.CashAccFrom?.$Name : this.CashAccTo?.$Name;
}

function sumDir() {
	if (this.CashAccFrom?.Id && this.CashAccTo?.Id)
		return 0;
	return this.CashAccFrom?.Id ? -1 : 1;
}