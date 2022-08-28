
// dialog transactions
const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TStoreTrans.$Dir'() { return this.Dir == -1 ? 'Видаток' : 'Прибуток'; },
		'TCashAcc.$Name'() { return this.Name || this.No; },
		'TCashAcc.$Title'() { return this.IsCash ? '@[CashAccount]' : '@[Account]';}
	}	
};

export default template;

