
import { TRoot, TItem } from './item';

const template: Template = {
	properties: {
		'TItem.$Title'(this: TItem) { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Item.Name': '@[Error.Required]'
	}
};

export default template;
