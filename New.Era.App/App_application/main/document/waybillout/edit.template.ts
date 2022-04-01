
const dateUtils: UtilsDate = require("std:utils").date;
// waybill out
const template: Template = {
	properties: {
		'TRoot.$$TabNo': String,
		'TRow.Sum'() { return this.Price * this.Qty; },
		'TDocument.Sum': docSum
	},
	defaults: {
		'Document.Date': dateUtils.today(),
		'Document.Operation'(this: any) { return this.Operations[0]; }
	},
	events: {
		'Document.Rows[].add'(rows, row) { row.Qty = 1;}
	},
	commands: {
		apply
	}
};

export default template;

function docSum() {
	return this.Rows.reduce((p, c) => p + c.Sum, 0);
}

async function apply() {
	let ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('apply', { Id: this.Document.Id });
	alert(JSON.stringify(result));
	ctrl.$requery();

}


