// common documents


const utils: Utils = require("std:utils");
const dateUtils: UtilsDate = utils.date;
const currencyUtils: UtilsCurrency = utils.currency;

function docToBaseDoc(doc) {
	return {
		Id: doc.Id,
		Date: doc.Date,
		Sum: doc.Sum,
		OpName: doc.Operation.Name,
		Form: doc.Operation.Form,
		Done: doc.Done
	};
}


const template: Template = {
	properties: {
		'TDocBase.$Name': docBaseName,
		'TDocBase.$Icon'() { return this.Done ? 'success-green' : 'warning-yellow';},
		'TDocument.$CompanyAgentArg'() { return { Company: this.Company.Id, Agent: this.Agent.Id }; }
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
		'Document.Contract.change': contractChange,
		'Document.Agent.change': agentChange,
		'Document.Company.change': companyChange,
		'app.document.saved': handleLinkSaved,
		'app.document.apply': handleLinkApply
	},
	commands: {
		apply: {
			exec: apply,
			confirm: '@[Confirm.Apply]'
		},
		unApply: {
			exec: unApply,
			confirm: '@[Confirm.UnApply]'
		},
		createOnBase,
		openLinked
	},
	delegates: {
		canClose
	}
};

export default template;

// #region properties
function docBaseName() {
	return `${this.OpName}\nвід ${dateUtils.formatDate(this.Date)} на суму ${currencyUtils.format(this.Sum)}`;
}

// #endregion

// #region events
function contractChange(doc, contract) {
	if (contract.Agent.Id)
		doc.Agent = contract.Agent;
	if (contract.Company.Id)
		doc.Company = contract.Company;
}

function agentChange(doc, agent) {
	if (doc.Contract.Agent.Id !== agent.Id)
		doc.Contract.$empty();
}

function companyChange(doc, company) {
	if (doc.Contract.Company.Id !== company.Id)
		doc.Contract.$empty();
}

function handleLinkSaved(elem) {
	let wasDirty = this.$dirty;
	let doc = elem.Document;
	let found = this.Document.LinkedDocs.find(e => e.Id === doc.Id);
	if (found) {
		found.Sum = doc.Sum;
		found.Date = doc.Date;
		found.OpName = doc.Operation.Name;
	} else
		this.Document.LinkedDocs.$append(docToBaseDoc(doc));
	if (!wasDirty)
		this.$defer(() => this.$dirty = false);
}

function handleLinkApply(elem) {
	let wasDirty = this.$dirty;
	let found = this.Document.LinkedDocs.find(e => e.Id === elem.Id);
	if (found)
		found.Done = elem.Done;
	if (!wasDirty)
		this.$defer(() => this.$dirty = false);
}

// #endregion

// #region commands
async function apply() {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('apply', { Id: this.Document.Id });
	ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: true });
	ctrl.$requery();
}

async function unApply() {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('unApply', { Id: this.Document.Id });
	ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: false });
	ctrl.$requery();
}


async function createOnBase(link) {
	const ctrl: IController = this.$ctrl;

	await ctrl.$save();
	let res = await ctrl.$invoke('createonbase', { Document: this.Document.Id, LinkId: link.Id}, '/document/commands');

	let url = `/document/${res.Document.Form}/edit`;
	await ctrl.$showDialog(url, { Id: res.Document.Id });

}

async function openLinked(doc) {
	const ctrl: IController = this.$ctrl;
	let url = `/document/${doc.Form}/edit`;
	await ctrl.$showDialog(url, { Id: doc.Id });
}
// #endregion

// #region delegates
function canClose() {
	return this.$ctrl.$saveModified('@[Confirm.Document.SaveModified]');
}
// #endregion

