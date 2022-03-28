
const dateUtils: UtilsDate = require("std:utils").date;
// waybill out
const template: Template = {
	properties: {
		'TRoot.$TabNo': String
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

function apply() {
	alert('apply');
}

