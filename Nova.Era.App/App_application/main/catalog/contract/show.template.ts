// contract.show.template

const template: Template = {
	properties: {
		'TRoot.$$Tab': String
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
	await ctrl.$showDialog(url, { Id: doc.Id });
}