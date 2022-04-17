
// dialog transactions
const template: Template = {
	properties: {
		'TCashAcc.$Name'() { return this.Name || this.No; },
		'TCashAcc.$Title'() { return this.IsCash ? '@[CashAccount]' : '@[Account]';}
	}	
};

export default template;

