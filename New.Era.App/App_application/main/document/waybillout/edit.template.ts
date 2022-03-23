
const dateUtils: UtilsDate = require("std:utils").date;
// waybill out
const template: Template = {
	defaults: {
		'Document.Date': dateUtils.today(),
		'Document.Operation'(this: any) { return this.Params.Operation;}
	},
	properties: {
	},
	commands: {
		apply
	}
};

export default template;

function apply() {
	alert('apply');
}

