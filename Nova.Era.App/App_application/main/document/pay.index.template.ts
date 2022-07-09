// document pay index

const base: Template = require("document/_common/index.module");
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
		'TDocument.$CashAccount': cashAccountText
	}
};

export default utils.mergeTemplate(base, template);

function cashAccountText() {
	console.log(this, this.CashAccFrom?.Id, this.CashAccFrom?.Id);
	if (this.CashAccFrom?.Id && this.CashAccFrom?.Id)
		return `${this.CashAccFrom.$Name} -> ${this.CashAccTo.$Name}`;
	return this.CashAccFrom?.Id ? this.CashAccFrom?.$Name : this.CashAccTo?.$Name;
}
