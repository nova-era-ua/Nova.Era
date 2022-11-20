

const template: Template = {
	properties: {
		'TOption.$Items'() { return this.Items.map(x => x.Name).join(', ') }
	},
	events: {
	},
	commands: {
	}
};

export default template;
