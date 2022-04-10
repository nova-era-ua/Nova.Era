
const template: Template = {
	properties: {
		'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
		'TAccount.$Icon'() { return 'account-folder'; }
	}
};

export default template;

