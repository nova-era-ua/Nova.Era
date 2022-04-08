
const dateUtils: UtilsDate = require("std:utils").date;

const template: Template = {
	defaults:{
		'Document.Operation'(this: any) { return this.Operations[0]; },
		'Document.Date': dateUtils.today(),
	},
	properties: {
	},
	commands: {
	}
};

export default template;

