
const template: Template = {
	defaults: {
		'Report.Menu'(this: any) { return this.Params.Menu; }
	},
	properties: {
		'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
		'TReport.$RepTypes': repTypes
	}
}

export default template;

function repTypes() {
	let r = [];
	let acc = this.Account;
	if (acc.IsItem)
		r.push({ Name: 'Оборотная ведомость "Товар"', Url: '/reports/stock/rto_items' });
	if (acc.IsWarehouse)
		r.push({ Name: 'Оборотная ведомость "Склад+товар"', Url: '/reports/stock/rto_whitems' });
	return r;
}