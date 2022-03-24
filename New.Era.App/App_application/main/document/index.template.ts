
import { TRoot, TDocument, TDocuments } from './index';

const template: Template = {
	properties: {
	},
	commands: {
		create,
		editSelected,
		edit
	}
};

export default template;

async function create(this: TRoot) {
	const ctrl = this.$ctrl;
	let sel = this.Operations.$selected;
	if (!sel) return;
	let url = `/document/${sel.Form.Url}/edit`
	let docsrc = await ctrl.$showDialog(url, null, { Operation: sel.Id });
	let doc = sel.Documents.$append(docsrc);
	doc.$select();
}

function editSelected(docs: TDocuments) {
	let doc = docs.$selected;
	if (!doc) return;
	alert(doc);
	edit.call(this, doc);
}

async function edit(this: TRoot, doc: TDocument) {
	if (!doc) return;
	const ctrl = this.$ctrl;
	let url = `/document/${doc.Operation.Form.Url}/edit`
	let rdoc = await ctrl.$showDialog(url, { Id: doc.Id });
	doc.$merge(rdoc);
}