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
		DocumentUrl: doc.Operation.DocumentUrl,
		Done: doc.Done,
		BindKind: doc.BindKind,
		BindFactor: doc.BindFactor
	};
}

function category2Text(cat) {
	switch (cat) {
		case 'Payment': return '@[KindPayment]';
		case 'Shipment': return '@[KindShipment]';
		case 'Return': return '@[KindReturn]';
		case 'RetMoney': return '@[KindRetMoney]';
	}
	return cat;
}

const template: Template = {
	properties: {
		'TDocBase.$Name': docBaseName,
		'TDocBase.$Icon'() { return this.Done ? 'success-green' : 'warning-yellow'; },
		'TDocBase.$BindKind'() { return category2Text(this.BindKind); },
		'TDocument.$CompanyAgentArg'() { return { Company: this.Company.Id, Agent: this.Agent.Id }; },
		'TOpLink.$Category'() { return category2Text(this.Category); }
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
		'Document.Date.change': dateChange,
		'app.document.saved': handleLinkSaved,
		'app.document.apply': handleLinkApply,
		'app.document.delete': handleLinkDelete
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
		openLinked,
		setBaseDoc,
		clearBaseDoc: {
			exec: clearBaseDoc,
			confirm: '@[Confirm.Document.Unbind]'
		},
		deleteSelf: {
			exec: deleteSelf,
			canExec(doc) { return !doc.Done; },
			confirm: '@[Confirm.Delete.Document]'
		}
	},
	delegates: {
		canClose,
		docToBaseDoc
	},
};

export default template;

// #region properties
function docBaseName() {
	return this.Id ? `${this.OpName}\nвід ${dateUtils.formatDate(this.Date)} на суму ${currencyUtils.format(this.Sum)}` : '';
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
	doc.No = '';
}

function dateChange(doc, date) {
	doc.No = '';
}

function chlidDocuments(doc) {
	return [].concat(doc.LinkedDocs, doc.BaseDoc ? [doc.BaseDoc] : [], doc.ParentDoc ? [doc.ParentDoc] : []);
}

function setDocFromEvent(trg, src) {
	trg.Sum = src.Sum;
	trg.Date = src.Date;
	trg.OpName = src.Operation.Name;
	trg.BindKind = src.BindKind;
	trg.BindFactor = src.BindFactor;
}

function handleLinkSaved(elem) {
	let ctrl: IController = this.$ctrl;
	ctrl.$nodirty(async () => {
		let doc = elem.Document;
		let chdocs = chlidDocuments(this.Document);
		let found = chdocs.find(e => e.Id === doc.Id);
		if (found)
			setDocFromEvent(found, doc);
		else {
			this.Document.LinkedDocs.$append(docToBaseDoc(doc));
		}
		ctrl.$emitCaller('app.document.saved', elem);
		ctrl.$emitCaller('app.document.link', this.Document);
	});
}

function handleLinkApply(elem) {
	let ctrl: IController = this.$ctrl;
	ctrl.$nodirty(async () => {
		let found = chlidDocuments(this.Document).find(e => e.Id === elem.Id);
		if (found)
			found.Done = elem.Done;
		ctrl.$emitCaller('app.document.apply', elem);
	});
}

function handleLinkDelete(elem) {
	let ctrl: IController = this.$ctrl;
	ctrl.$nodirty(async () => {
		let found = chlidDocuments(this.Document).find(e => e.Id === elem.Id);
		if (found)
			found.$remove();
		ctrl.$emitCaller('app.document.delete', elem);
		ctrl.$emitCaller('app.document.link', this.Document);
	});
}

// #endregion

// #region commands
async function apply() {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('apply', { Id: this.Document.Id }, '/document/commands');
	ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: true });
	ctrl.$requery();
}

async function unApply() {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('unApply', { Id: this.Document.Id }, '/document/commands');
	ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: false });
	ctrl.$requery();
}

async function deleteSelf(doc) {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('delete', { Id: doc.Id }, '/document/commands');
	ctrl.$emitCaller('app.document.delete', { Id: doc.Id });
	ctrl.$modalClose(false);
}

async function createOnBase(link) {
	const ctrl: IController = this.$ctrl;

	await ctrl.$save();
	let res = await ctrl.$invoke('createonbase', { Document: this.Document.Id, LinkId: link.Id}, '/document/commands');

	let url = `${res.Document.DocumentUrl}/edit`;
	await ctrl.$showDialog(url, { Id: res.Document.Id });

}

async function openLinked(doc) {
	const ctrl: IController = this.$ctrl;
	let url = `${doc.DocumentUrl}/edit`;
	await ctrl.$showDialog(url, { Id: doc.Id });
}

async function setBaseDoc() {
	const ctrl: IController = this.$ctrl;
	if (!this.Document.Id) {
		// esnure saved
		this.$setDirty(true);
		await ctrl.$save();
	}
	ctrl.$nodirty(async () => {
		let result = await ctrl.$showDialog('/document/dialogs/browsebase', { Id: this.Document.Id }, { Agent: this.Document.Agent.Id });
		await ctrl.$invoke('setBaseDoc', { Id: this.Document.Id, Base: result.Id }, '/document/commands')
		this.Document.BaseDoc.$merge(result);
	});
}

async function clearBaseDoc() {
	const ctrl: IController = this.$ctrl;
	ctrl.$nodirty(async () => {
		let result = await ctrl.$invoke('clearbasedoc', { Id: this.Document.Id }, '/document/commands');
		this.Document.BaseDoc.$empty();
	});
}

// #endregion

// #region delegates
function canClose() {
	return this.$ctrl.$saveModified('@[Confirm.Document.SaveModified]');
}
// #endregion

