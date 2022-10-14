
const template: Template = {
	properties: {
		'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
	},
};

export default template;