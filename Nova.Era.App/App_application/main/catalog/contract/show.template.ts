// contract.show.template

const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TDocument.$Mark'() { return this.Done ? 'green' : undefined; },
	},
	commands: {
		editDocument
	}
};

export default template;



async function editDocument(doc) {
	if (!doc) return;
	const ctrl = this.$ctrl;
	let url = `${doc.Operation.DocumentUrl}/edit`
	let res = await ctrl.$showDialog(url, { Id: doc.Id });
	doc.$merge(res);
}