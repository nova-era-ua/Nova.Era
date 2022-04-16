
const tu: UtilsText = require('std:utils').text;

const template: Template = {
	properties: {
		'TRoot.$Search': String,
		'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
		'TAccount.$Icon'() { return this.IsFolder ? 'account-folder' : 'account'; }
	},
	events: {
		'Root.$Search.change': searchAccount,
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