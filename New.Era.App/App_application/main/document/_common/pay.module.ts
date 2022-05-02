
const dateUtils: UtilsDate = require("std:utils").date;

// common module for pay documents

const template: Template = {
	properties: {
		'TRoot.$CompArg'() { return { Company: this.Document.Company?.Id }; }
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

