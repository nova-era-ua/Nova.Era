
const base: Template = require('/document/_common/stock.module');
const utils: Utils = require("std:utils");

// waybill out
const template: Template = {
	properties: {
		'TRoot.$BrowseStockArg'() { return { IsStock: 'T', PriceKind: this.Document.PriceKind.Id, Date: this.Document.Date }; },
		'TRoot.$BrowseServiceArg'() { return { IsStock: 'V', PriceKind: this.Document.PriceKind.Id, Date: this.Document.Date }; }
	},
	defaults: {
		'Document.WhFrom'(this: any) { return this.Default.Warehouse; }
	},
	validators: {
		'Document.WhFrom': '@[Error.Required]',
		'Document.StockRows[].Price': '@[Error.Required]',
		'Document.ServiceRows[].Price': '@[Error.Required]'
	},
	events: {
		'Document.Date.change': dateChange,
		'Document.Contract.change': contractChange,
		'Document.StockRows[].Item.change': itemChange,
		'Document.ServiceRows[].Item.change': itemChange,
		'Document.PriceKind.change': priceKindChange
	}
};

export default utils.mergeTemplate(base, template);

// #region events

function contractChange(doc, contract) {
	doc.PriceKind.$set(contract.PriceKind);
}

function itemChange(row, val) {
	base.events['Document.StockRows[].Item.change'].call(this, row, val);
	row.Price = val.Price;
}


async function dateChange(doc) {
	if (!doc.PriceKind.Id) return;
	if (doc.StockRows.$isEmpty && doc.ServiceRows.$isEmpty) return;

	const ctrl: IController = this.$ctrl;
	if (!await ctrl.$confirm('Дата документу змінилася. Оновити ціни в документі?'))
		return;
	priceChange.call(this, doc);
}

async function priceKindChange(doc) {
	if (!doc.PriceKind.Id) return;
	if (doc.StockRows.$isEmpty && doc.ServiceRows.$isEmpty) return;

	const ctrl: IController = this.$ctrl;
	if (!await ctrl.$confirm('Тип ціни змінився. Оновити ціни в документі?'))
		return;
	priceChange.call(this, doc);
}

async function priceChange(doc) { 
	const ctrl: IController = this.$ctrl;
	let stocks = doc.StockRows.map(r => r.Item.Id);
	let services = doc.ServiceRows.map(r => r.Item.Id);
	let items = stocks.concat(services).join(',');
	let result = await ctrl.$invoke('getPrices', { Items: items, PriceKind: doc.PriceKind.Id, Date: doc.Date });

	doc.StockRows.concat(doc.ServiceRows).forEach(row => {
		let price = result.Prices.find(p => p.Item === row.Item.Id);
		row.Price = price?.Price || 0;
	})
}

// #endregion