// stock documents

import { TRow, TDocument } from 'stock.d';

const utils: Utils = require("std:utils");

const base: Template = require('/document/_common/common.module');

const template: Template = {
	properties: {
		'TRoot.$$TabNo': String,
		'TRow.Sum': {
			get(this: TRow) { return this.Price * this.Qty; },
			set(this: TRow, val: number) { this.Qty = val / this.Price; }
		},
		'TRoot.$StockItemRoles'() { return this.ItemRoles.filter(r => r.IsStock); },
		'TDocument.Sum': docSum,
		'TDocument.$StockSum': stockSum,
		'TDocument.$ServiceSum': serviceSum,
		'TDocument.$StockESum': stockESum,

	},
	validators: {
		'Document.StockRows[].Item': '@[Error.Required]',
		'Document.ServiceRows[].Item': '@[Error.Required]',
	},
	events: {
		'Document.StockRows[].add'(rows, row: TRow) { row.Qty = 1; },
		'Document.StockRows[].Item.change': itemChange,
		'Document.StockRows[].Item.Article.change': articleChange,
		'Document.ServiceRows[].add'(rows, row) { row.Qty = 1; },
		'Document.ServiceRows[].Item.change': itemChange,
		'Document.ServiceRows[].Item.Article.change': articleChange
	},
	commands: {
	}
};

export default utils.mergeTemplate(base, template);

function docSum(this: TDocument) {
	return this.$StockSum + this.$ServiceSum;
}

function stockSum(this: TDocument) {
	return this.StockRows.reduce((p:number, c:TRow) => p + c.Sum, 0);
}

function stockESum(this: TDocument) {
	return this.StockRows.reduce((p: number, c: TRow) => p + c.ESum, 0);
}

function serviceSum(this: TDocument) {
	return this.ServiceRows.reduce((p:number, c:TRow) => p + c.Sum, 0);
}

// events
function itemChange(row: TRow, val) {
	row.Unit = val.Unit;
	row.ItemRole = val.Role;
}

async function articleChange(item, val) {
	if (!val) {
		item.$empty();
		return;
	};
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('findArticle', {
			Text: val,
			PriceKind: this.Document.PriceKind.Id,
			Date: this.Document.Date
		},
		'/catalog/item'
	);
	result?.Item ? item.$merge(result.Item) : item.$empty();
}
