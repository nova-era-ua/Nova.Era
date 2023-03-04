
import { TRoot, TItem, TItemRole } from './item';

const barcode = require('std:barcode');

const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TItem.$Title'(this: TItem) { return `@[Item] [${this.Id ? this.Id : '@[NewItem]'}]`; },
		'TItem.$HasVariants'() { return this.Variants.length > 0; }
	},
	defaults: {
		'Item.Role'(this: TRoot) { return this.ItemRoles.$isEmpty ? undefined : this.ItemRoles[0]; }
	},
	validators: {
		'Item.Name': '@[Error.Required]',
		'Item.Role': '@[Error.Required]',
		'Item.Unit': '@[Error.Required]'
	},
	commands: {
		addHierarchy,
		generateBarcode,
		addVariant
	},
	delegates: {
		fetchUnit
	},
	events: {
		'variant.saved': handleSavedVariant
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

function fetchUnit(item, text) {
	if (!text) return [];
	return this.$ctrl.$invoke('fetch', {Text: text}, '/catalog/unit');
}

async function generateBarcode(item) {
	if (this.Item.$isNew) {
		this.$setDirty(true);
		await this.$ctrl.$save();
	}
	item.Barcode = barcode.generateEAN13('20', item.Id);
}

async function addVariant(item) {
	const ctrl: IController = this.$ctrl;
	if (!item.Id) {
		// esnure saved
		this.$setDirty(true);
		await ctrl.$save();
	}
	let vars = await ctrl.$showDialog('/catalog/item/createvariant', { Id: item.Id });
	item.Variants.$copy(vars.Result);
	ctrl.$emitSaveEvent();
}

function handleSavedVariant(root) {
	const ctrl: IController = this.$ctrl;
	let elem = root.Variant;
	let found = this.Item.Variants.$find(x => x.Id == elem.Id);
	if (found) {
		let wasDirty = this.$dirty;
		found.$merge(elem);
		ctrl.$defer(() => {
			this.$setDirty(wasDirty);
		})
		ctrl.$emitSaveEvent();
	}
}
