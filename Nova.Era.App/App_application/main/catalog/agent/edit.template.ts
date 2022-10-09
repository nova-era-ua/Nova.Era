
const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TAgent.$Title'() {return this.Id || '@[NewItem]'}
	},
	validators: {
		'Agent.Name': '@[Error.Required]'
	},
	commands: {
		addContact
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