


const base: Template = require("document/_common/index.module");

const tmlUtils = require('std:tmlutils');

const template: Template = {
	properties: {
		'TBankAccount.$Name'() { return this.Name || this.AccountNo;},
		'TDocument.$BankAccount'() { return this.BankAccFrom?.Id ? this.BankAccFrom?.$Name : this.BankAccTo?.$Name; },
		'TDocument.$CashAccount'() { return this.CashAccFrom?.Id ? this.CashAccFrom?.Name : this.CashAccTo?.Name; }
	}
};

export default tmlUtils.mergeTemplate(base, template);

