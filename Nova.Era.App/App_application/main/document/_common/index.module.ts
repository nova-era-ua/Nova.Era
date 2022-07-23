
import { TRoot, TDocument, TDocuments, TMenu } from './index';

const template: Template = {
	options: {
		persistSelect:['Documents']
	},
	properties: {
		'TDocument.$No'() { return this.SNo; },
		'TDocument.$Mark'(this: TDocument) { return this.Done ? 'green' : undefined; },
	},
	events: {
		'app.document.saved': handleSaved,
		'app.document.apply': handleApply
	},
	commands: {
		clearFilter,
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
		}
	}
};

export default template;

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

function clearFilter(elem) {
	elem.Id = 0;
	elem.Name = '';
}

// events
function handleSaved(savedRoot) {
	const savedDoc = savedRoot.Document;
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

async function deleteDoc(doc: TDocument) {
	const ctrl = this.$ctrl;
	ctrl.$invoke('delete', {Id: doc.Id}, '/document/commands')
	doc.$remove();
}