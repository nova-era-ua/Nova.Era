import { TRoot, TAccount } from './edit'

const template: Template = {
	properties: {
		'TRoot.$TabMode': String,
		'TAccount.$Title'(this: TAccount) { return this.Id ? this.Id : '@[NewItem]' },
	},
	defaults: {
		'Account.ParentAccount'(this:TRoot) { return this.Params.ParentAccount;}
	},
	validators: {
		'Account.Code': '@[Error.Required]',
		'Account.Name': '@[Error.Required]'
	}
};

export default template;

