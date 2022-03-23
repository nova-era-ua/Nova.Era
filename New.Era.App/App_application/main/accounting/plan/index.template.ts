import { TAccount, TRoot } from './index';

const template: Template = {
	properties: {
		'TAccount.$Title'(this: TAccount) { return `${this.Code} ${this.Name}`; },
		'TAccount.$Icon'() { return 'account-folder'; },
		'TAccount.$IsPlan'() { return this.Plan === 0; }
	},
	commands: {
	}
};

export default template;

