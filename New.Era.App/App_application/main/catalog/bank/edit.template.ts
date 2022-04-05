// bank.template

import {TBank} from './edit'

const template: Template = {
	properties: {
		'TBank.$Id'(this: TBank) { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Bank.Name': '@[Error.Required]',
		'Bank.BankCode': '@[Error.Required]',
	}
};

export default template;
