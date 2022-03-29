
const dateUtils: UtilsDate = require("std:utils").date;
// waybill out
const template: Template = {
	properties: {
		'TRoot.$$TabNo': String
	},
	defaults: {
		'Document.Date': dateUtils.today(),
		'Document.Operation'(this: any) { return this.Operations[0]; }
	},
	commands: {
		apply
	}
};

export default template;

async function apply() {
	let ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('apply', { Id: this.Document.Id });
	alert(JSON.stringify(result));
	ctrl.$requery();

}

