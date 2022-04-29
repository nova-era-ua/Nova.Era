
import { TRoot, TItem } from './item';

const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TItem.$Title'(this: TItem) { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Item.Name': '@[Error.Required]',
		'Item.Role': '@[Error.Required]'
	},
	commands: {
		addHierarchy
	}
};

export default template;

async function addHierarchy(elems) {
	const ctrl: IController = this.$ctrl;
	let item = await ctrl.$showDialog('/catalog/itemgroup/browse', null, { Hierarchy: elems.$parent.Id });

	function makePath(item, sep) {
		let p = item.$parent.$parent;
		if (p !== item.$root)
			return makePath(p, sep) + sep + item.Name;
		return item.Name;
	}

	if (elems.find(h => h.Group === item.Id)) return; // already in list

	elems.$append({ Group: item.Id, Path: makePath(item, ' > ') });
}