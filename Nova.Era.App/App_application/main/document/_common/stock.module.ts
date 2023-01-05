// stock documents

import { TRow, TDocument } from 'stock.d';

const utils: Utils = require("std:utils");
const cu: UtilsCurrency = utils.currency;

const base: Template = require('/document/_common/common.module');

const template: Template = {
	properties: {
		'TRoot.$$TabNo': String,
		'TRoot.$$Barcode': String,
		'TRow.Sum': {
			get(this: TRow) { return cu.round(this.Price * this.Qty, 2); },
			set(this: TRow, val: number) { this.Qty = cu.round(val / this.Price, 2); }
		},
		'TRoot.$StockItemRoles'() { return this.ItemRoles.filter(r => r.Kind == "Item" && r.IsStock); },
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
		'Root.$$Barcode.change': scanBarcode,
		'Document.StockRows[].add'(rows, row: TRow) { row.Qty = 1; },
		'Document.StockRows[].Item.change': itemChange,
		'Document.StockRows[].Item.Article.change': articleChange,
		'Document.StockRows[].Item.Barcode.change': barcodeChange,
		'Document.ServiceRows[].add'(rows, row) { row.Qty = 1; },
		'Document.ServiceRows[].Item.change': itemChange,
		'Document.ServiceRows[].Item.Article.change': articleChange,
		'Document.ServiceRows[].Item.Barcode.change': barcodeChange
	},
	commands: {
	},
	delegates: {
		itemBrowsePrice,
		itemBrowseService
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

// #region events
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
		Date: this.Document.Date,
		Wh: this.Document.WhFrom.Id,
		Stock: !this.$$TabNo
		
	},'/catalog/item');
	result?.Item ? item.$merge(result.Item) : item.$empty();
}

async function barcodeChange(item, val) {
	if (!val) {
		item.$empty();
		return;
	};
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('findBarcode', {
		Text: val,
		PriceKind: this.Document.PriceKind.Id,
		Date: this.Document.Date,
		Wh: this.Document.WhFrom.Id,
		Stock: !this.$$TabNo
	}, '/catalog/item');
	result?.Item ? item.$merge(result.Item) : item.$empty();
}

async function scanBarcode(root, val) {
	if (!val) return;
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('findBarcode', {
		Text: val,
		PriceKind: this.Document.PriceKind.Id,
		Date: this.Document.Date,
		Wh: this.Document.WhFrom.Id
		/*Without stock*/
	}, '/catalog/item');
	root.$$Barcode = '';
	if (!result?.Item) {
		ctrl.$alert('@[Error.Barcode.NotFound]');
		return;
	}
	let itm = result.Item;
	let rows = itm.Role.IsStock ? root.Document.StockRows : root.Document.ServiceRows;
	root.$$TabNo = itm.Role.IsStock ? '' : 'service';

	var found = rows.find(row => row.Item.Id == itm.Id);
	if (found)
		found.Qty += 1;
	else {
		var newrow = rows.$append();
		newrow.Item.$merge(itm);
		newrow.Qty = 1;
	}
}

// #endregion

// #region delegates

function itemBrowsePrice(item, text) {
	let ctrl: IController = this.$ctrl;
	let arg = this.$root.$BrowseStockArg;
	arg.Text = text;
	return ctrl.$invoke('fetchprice', arg, '/catalog/item');
}

function itemBrowseService(item, text) {
	let ctrl: IController = this.$ctrl;
	let arg = this.$root.$BrowseServiceArg;
	arg.Text = text;
	return ctrl.$invoke('fetchprice', arg, '/catalog/item');
}

// #endregion