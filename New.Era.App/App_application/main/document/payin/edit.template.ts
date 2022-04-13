
const dateUtils: UtilsDate = require("std:utils").date;
// waybill out
const template: Template = {
	properties: {
		'TRoot.$CompArg'() { return { Company: this.Document.Company?.Id }; },
		'TBankAccount.$Name'() { return this.Name || this.AccountNo;}
	},
	defaults: {
		'Document.Date': dateUtils.today(),
		'Document.Operation'(this: any) { return this.Operations[0]; },
		'Document.Company'(this: any) { return this.Default.Company;}
	},
	validators: {
		'Document.Company': '@[Error.Required]',
		'Document.Agent': '@[Error.Required]',
		'Document.BankAccTo': '@[Error.Required]'
	},
	events: {
	},
	commands: {
		apply,
		unApply
	}
};

export default template;


async function apply() {
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('apply', { Id: this.Document.Id });
	ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: true });
	ctrl.$requery();
}

async function unApply() {
	let ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('unApply', { Id: this.Document.Id });
	ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: false });
	ctrl.$requery();
}

