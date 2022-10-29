
import { TRoot, TDocument, TDocuments, TMenu } from './index';

const utils: Utils = require("std:utils");
const dateUtils: UtilsDate = utils.date;

const template: Template = {
	options: {
		persistSelect: ['Documents']
	},
	properties: {
		'TDocument.$No'() { return this.SNo || this.No; },
		'TDocument.$Mark'(this: TDocument) { return this.Done ? 'green' : undefined; },
		'TDocBase.$ShortName': docBaseName,
		'TDocBase.$Icon'() { return this.Done ? 'success-green' : 'warning-yellow'; },
		'TDocBase.$EditUrl'() { return `${this.DocumentUrl}/edit` },
	},
	events: {
		'app.document.saved': handleSaved,
		'app.document.apply': handleApply,
		'app.document.delete': handleDelete
	},
	commands: {
		create,
		editSelected: {
			exec: editSelected,
			canExec(docs: TDocuments) { return docs.$hasSelected; }
		},
		edit,
		delete: {
			exec: deleteDoc,
			canExec(doc: TDocument) { return !doc.Done; },
			confirm:'@[Confirm.Delete.Element]'
		},
		copy: {
			exec: copyDoc,
			canExec(docs: TDocuments) { return docs.$hasSelected; },
		}
	}
};

export default template;


function docBaseName() {
	return this.Id ? `№${this.No} [${dateUtils.formatDate(this.Date)}]` : '';
}

async function create(this: TRoot, menu: TMenu) {
	const ctrl = this.$ctrl;
	let url = `${menu.DocumentUrl}/edit`
	await ctrl.$showDialog(url, null, { Operation: menu.Id });
}

function editSelected(docs: TDocuments) {
	let doc = docs.$selected;
	if (!doc) return;
	edit.call(this, doc);
}

async function edit(this: TRoot, doc: TDocument) {
	if (!doc) return;
	const ctrl = this.$ctrl;
	let url = `${doc.Operation.DocumentUrl}/edit`
	await ctrl.$showDialog(url, { Id: doc.Id });
}

// events
function handleSaved(savedRoot) {
	const savedDoc = savedRoot.Document;
	let opid = savedDoc.Operation.Id;
	if (!this.Operations.some(x => x.Id === opid))
		return;
	let found = this.Documents.find(d => d.Id == savedDoc.Id);
	if (found)
		found.$merge(savedDoc)
	else {
		let newDoc = this.Documents.$append(savedDoc);
		newDoc.$select();
	}
}

function handleApply(elem) {
	let found = this.Documents.find(d => d.Id == elem.Id);
	if (!found) return;
	found.Done = elem.Done;
}

function handleDelete(elem) {
	let found = this.Documents.find(d => d.Id == elem.Id);
	if (!found) return;
	found.$remove();
}

async function deleteDoc(doc: TDocument) {
	const ctrl = this.$ctrl;
	await ctrl.$invoke('delete', { Id: doc.Id }, '/document/commands');
	doc.$remove();
}

async function copyDoc(docs: TDocuments) {
	if (!docs.$hasSelected) return;
	const ctrl = this.$ctrl;
	const doc = docs.$selected;
	let res = await ctrl.$invoke('copy', { Id: doc.Id }, '/document/commands');
	let url = `${res.Document.DocumentUrl}/edit`
	await ctrl.$showDialog(url, { Id: res.Document.Id });
}