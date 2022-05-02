// stock documents

const dateUtils: UtilsDate = require("std:utils").date;

const template: Template = {
	properties: {
		'TRoot.$$TabNo': String,
		'TRow.Sum'() { return this.Price * this.Qty; },
		'TDocument.Sum': docSum,
		'TDocument.$StockSum': stockSum,
		'TDocument.$ServiceSum': serviceSum
	},
	defaults: {
		'Document.Date': dateUtils.today(),
		'Document.Operation'(this: any) { return this.Operations.find(o => o.Id === this.Params.Operation); },
		'Document.Company'(this: any) { return this.Default.Company; },
		'Document.RespCenter'(this: any) { return this.Default.RespCenter; }
	},
	validators: {
		'Document.Company': '@[Error.Required]',
		'Document.Agent': '@[Error.Required]',
	},
	events: {
		'Document.StockRows[].add'(rows, row) { row.Qty = 1; },
		'Document.StockRows[].Item.change': itemChange,
		'Document.StockRows[].Item.Article.change': articleChange,
		'Document.ServiceRows[].add'(rows, row) { row.Qty = 1; },
		'Document.ServiceRows[].Item.change': itemChange,
		'Document.ServiceRows[].Item.Article.change': articleChange
	},
	commands: {
		apply,
		unApply
	}
};

export default template;

function docSum() {
	return this.$StockSum + this.$ServiceSum;
}

function stockSum() {
	return this.StockRows.reduce((p, c) => p + c.Sum, 0);
}

function serviceSum() {
	return this.ServiceRows.reduce((p, c) => p + c.Sum, 0);
}

// events
function itemChange(row, val) {
	row.Unit = val.Unit;
	row.ItemRole = val.ItemRole;
}

async function articleChange(item, val) {
	if (!val) {
		item.$empty();
		return;
	};
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('findArticle', { Text: val }, '/catalog/item');
	result?.Item ? item.$merge(result.Item) : item.$empty();
}

async function apply() {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('apply', { Id: this.Document.Id });
	ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: true });
	ctrl.$requery();
}

async function unApply() {
	let ctrl: IController = this.$ctrl;
	await ctrl.$invoke('unApply', { Id: this.Document.Id });
	ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: false });
	ctrl.$requery();
}

