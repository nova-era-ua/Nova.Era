
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
	let operation = await ctrl.$showDialog(url, null, { Operation: sel.Id });
	console.dir(operation);
}

function editSelected(docs: TDocuments) {
	alert('editSelected')
}

async function edit(this: TRoot, doc: TDocument) {
	const ctrl = this.$ctrl;
	if (!doc) return;
	let url = `/document/${doc.FormUrl}/edit`
	let rdoc = await ctrl.$showDialog(url, { Id: doc.Id });
	console.dir(rdoc);
}