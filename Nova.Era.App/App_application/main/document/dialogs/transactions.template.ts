
// dialog transactions
const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TStoreTrans.$Dir'() { return this.Dir == -1 ? 'Видаток' : 'Прибуток'; },
		'TCashAcc.$Name'() { return this.Name || this.No; },
		'TCashAcc.$Title'() { return this.IsCash ? '@[CashAccount]' : '@[Account]';},
		'TCashTrans.$Dir'() { return this.InOut == -1 ? 'Видаток' : 'Прибуток'; },
		'TSettleTrans.$Dir'() { return this.IncDec == -1 ? 'Зменьшення' : 'Збільшення'; },
	}	
};

export default template;

