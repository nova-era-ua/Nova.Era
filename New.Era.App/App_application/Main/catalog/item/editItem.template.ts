
import { TItem, TParentFolder, TRoot } from 'item.d';

const template: Template = {
	validators: {
		'Item.Name': StdValidator.notBlank
	},
	defaults: {
		"Item.ParentFolder"(this: TRoot) { return this.ParentFolder; }
	}
};

export default template;
