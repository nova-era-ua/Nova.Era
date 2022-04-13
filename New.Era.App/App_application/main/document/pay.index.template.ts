
const base: Template = require("document/_common/index.module");

const template: Template = Object.assign(base, {
	properties: Object.assign(base.properties, {
		'TBankAccount.$Name'() { return this.Name || this.AccountNo;},
		'TDocument.$BankAccount'() { return this.BankAccFrom?.Id ? this.BankAccFrom?.$Name : this.BankAccTo?.$Name; }
	})
});

export default template;

