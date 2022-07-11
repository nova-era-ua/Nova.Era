// contract.edit.template

const dateUtils: UtilsDate = require("std:utils").date;

const template: Template = {
	properties: {
		'TContract.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Contract.Company': '@[Error.Required]',
		'Contract.Agent': '@[Error.Required]',
		'Contract.Kind': '@[Error.Required]'
	},
	defaults: {
		'Contract.Date': dateUtils.today(),
		'Contract.Company'(this: any) { return this.Params.Company.Id ? this.Params.Company : this.Default.Company; },
		'Contract.Agent'(this: any) { return this.Params.Agent; }
	}
};

export default template;
