// document pay index

const base: Template = require("document/_common/index.module");
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRoot.$CashAccLabel': cashAccText,
		'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
		'TDocument.$SumDir': sumDir,
		'TDocument.$CashAccount': cashAccountText
	},
	commands: {
		browseCashAccount
	},
	delegates: {
		browseCashDelegate
	}
};

export default utils.mergeTemplate(base, template);

function cashAccText() {
	return this.Params.AccMode === 'Cash' ? '@[CashAccount]' :
		this.Params.AccMode === 'Bank' ? '@[BankAccount]' :
			'@[Label.Cash.Account]';
}

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

async function browseCashAccount(filter) {
	const ctrl: IController = this.$ctrl;
	let url = '/catalog/cashaccount/browseall';
	let dat = {
		Company: filter.Company.Id,
		Mode: this.Params.AccMode
	};
	let res = await ctrl.$showDialog(url, filter.CashAccount, dat);
	filter.CashAccount.Id = res.Id;
	filter.CashAccount.Name = res.Name;
}

function browseCashDelegate(item, text) {
	const ctrl: IController = this.$ctrl;
	let url = '/catalog/cashaccount';
	let filter = this.Documents?.$ModelInfo?.Filter;
	let dat = {
		Company: filter.Company.Id,
		Mode: this.Params.AccMode,
		Text : text
	};
	return ctrl.$invoke('fetchall', dat, url)
}