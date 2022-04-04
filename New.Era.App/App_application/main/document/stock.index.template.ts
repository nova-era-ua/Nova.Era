
import { TRoot, TDocument, TDocuments, TForm } from './index';

const template: Template = {
	options: {
		persistSelect:['Documents']
	},
	properties: {
		'TDocument.$Mark'(this: TDocument) { return this.Done ? 'green' : undefined; },
		'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name;}
	},
	events: {
		'app.document.saved': docSaved
	},
	commands: {
		clearFilter,
		create,
		editSelected,
		edit
	}
};

export default template;

async function create(this: TRoot, form: TForm) {
	const ctrl = this.$ctrl;
	let url = `/document/${form.Id}/edit`
	await ctrl.$showDialog(url, null, { Form: form.Id });
}

function editSelected(docs: TDocuments) {
	let doc = docs.$selected;
	if (!doc) return;
	edit.call(this, doc);
}

async function edit(this: TRoot, doc: TDocument) {
	if (!doc) return;
	const ctrl = this.$ctrl;
	let url = `/document/${doc.Operation.Form}/edit`
	await ctrl.$showDialog(url, { Id: doc.Id });
}

function clearFilter(elem) {
	elem.Id = 0;
	elem.Name = '';
}

// events
function docSaved(savedRoot) {
	const savedDoc = savedRoot.Document;
	let found = this.Documents.find(d => d.Id == savedDoc.Id);
	if (found)
		found.$merge(savedDoc)
	else {
		let newDoc = this.Documents.$append(savedDoc);
		newDoc.$select();
	}
}