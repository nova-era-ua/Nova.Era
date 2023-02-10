
const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TAgent.$Title'() { return this.Id || '@[NewItem]' },
	},
	validators: {
		'Agent.Name': '@[Error.Required]'
	},
	commands: {
		addContact
	},
	delegates: {
		tagSettings
	}
};

export default template;

async function addContact() {
	const ctrl: IController = this.$ctrl;
	let ag = this.Agent;
	let contact = await ctrl.$showDialog('/catalog/contact/browse');
	if (ag.Contacts.find(c => c.Id === contact.Id))
		return; // already added
	ag.Contacts.$append(contact);
}

async function tagSettings(items) {
	const ctrl = this.$ctrl;
	let tags = await ctrl.$showDialog('/catalog/tag/settings', null, { For: 'Agent' });
	this.Tags.$copy(tags);
	this.Agent.Tags.forEach(lt => {
		let nt = tags.find(t => t.Id == lt.Id);
		if (nt) lt.$merge(nt);
	});
}