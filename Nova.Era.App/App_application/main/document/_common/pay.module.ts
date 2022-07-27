
const base: Template = require('/document/_common/common.module');
const utils: Utils = require("std:utils");

// common module for pay documents

const template: Template = {
	properties: {
		'TDocument.$CompanyArg'() { return { Company: this.Company?.Id }; },
		'TCashAccount.$Balance'() { return `@[Rem]: ${utils.currency.format(this.Balance)}`; },
		'TCashAccount.$InfoUrl'() { return `/catalog/cashaccount/info/${this.Id}`; }
	},
	events: {
		'Document.Date.change': dateChange
	}
};

export default utils.mergeTemplate(base, template);

async function dateChange(doc, date) {
	if (!doc.CashAccFrom.Id) return;
	const ctrl: IController = this.$ctrl;
	let res = await ctrl.$invoke('getrem', { Id: doc.CashAccFrom.Id, Date: doc.Date }, '/catalog/cashaccount');

	doc.CashAccFrom.Balance = res.Result.Balance;
}


