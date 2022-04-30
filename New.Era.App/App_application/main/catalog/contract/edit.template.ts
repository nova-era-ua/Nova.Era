// contract.edit.template

const dateUtils: UtilsDate = require("std:utils").date;

const template: Template = {
	properties: {
		'TContract.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Contract.Company': '@[Error.Required]',
		'Contract.Agent': '@[Error.Required]'
	},
	defaults: {
		'Contract.Date': dateUtils.today(),
		'Contract.Company'(this:any) { return this.Default.Company;}
	}
};

export default template;
