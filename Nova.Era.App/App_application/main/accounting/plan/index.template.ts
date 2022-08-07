import { TAccount, TRoot } from './index';

const tu: UtilsText = require('std:utils').text;


const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TRoot.$Search': String,
		'TAccount.$Title'(this: TAccount) { return `${this.Code} ${this.Name}`; },
		'TAccount.$Icon'(this: TAccount) { return this.IsFolder ? 'account-folder' : 'account'; },
		'TAccount.$IsPlan'(this: TAccount) { return this.Plan === 0; }
	},
	events: {
		'Root.$Search.change': searchAccount,
	},
	commands: {
		editDocument,
		editSelectedDocument
	}
};

export default template;

function searchAccount(root, text) {
	if (!text) return;
	let found = root.Accounts.$find(el => el.Code.indexOf(text) === 0 || tu.contains(el.Name, text));
	if (found)
		found.$select(root.Accounts);
	else
		root.$Search = '';
}

async function editSelectedDocument(docs) {
	if (!docs) return;
	let doc = docs.$selected;
	if (!doc) return;
	const ctrl = this.$ctrl;
	let url = `${doc.Operation.DocumentUrl}/edit`
	await ctrl.$showDialog(url, { Id: doc.Id });
}

async function editDocument(doc) {
	if (!doc) return;
	const ctrl = this.$ctrl;
	let url = `${doc.Operation.DocumentUrl}/edit`
	await ctrl.$showDialog(url, { Id: doc.Id });
}