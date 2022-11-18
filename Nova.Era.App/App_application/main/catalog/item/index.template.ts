const EDIT_URL = '/catalog/item/edit';
const EDIT_VARIANT_URL = '/catalog/item/editvariant';

const template: Template = {
	properties: {
		'TRoot.$SelectedElem': selectedElem,
		'TRoot.$$Check': Boolean,
		'TItem.$Mark'() { return this.IsVariant ? 'cyan' : null; },
		'TGroupArray.$HasElements'() {
			return this.$hasSelected && this.$selected.Elements;
		},
		'TGroupArray.$Elements'() {
			console.dir(this.$selected.Elements);
			if (!this.$hasSelected)
				return [];
			this.$selected.Elements.$load();
			return this.$selected.Elements.reduce((p, c) => p.concat(c, c.Variants), []);
		}
	},
	events: {
	},
	commands: {
		create,
		edit,
		editSelected: {
			exec: editSelected,
			canExec(coll) { return coll.$hasSelected; }
		},
		navigateSelected: {
			exec: navigate,
			canExec(coll) { return coll.$hasSelected; }
		}
	}
}

export default template;

function selectedElem() {
	let sel = this.Groups.$selected;
	if (!sel) return undefined;
	return sel.Elements.$selected?.Id;
}

function clearLazyElements(items, sel) {
	items.forEach(el => {
		clearLazyElements(el.Items, sel);
	});
}

async function create(coll) {
	const ctrl: IController = this.$ctrl;
	const res = await ctrl.$showDialog(EDIT_URL, null);
	coll.$append(res);
	clearLazyElements(this.Groups, this.Groups.$selected);
}

async function edit(item) {
	const ctrl: IController = this.$ctrl;
	const url = item.IsVariant ? EDIT_VARIANT_URL : EDIT_URL;
	let res = await ctrl.$showDialog(url, { Id: item.Id });
	if (item.IsVariant) {
		item.$merge(res, true, true);
	} else
		item.$merge(res);
	clearLazyElements(this.Groups, this.Groups.$selected);
}

async function editSelected(coll) {
	if (!coll.$hasSelected) return;
	await edit.call(this, coll.$selected);
}

function navigate(coll) {
	if (!coll.$hasSelected) return;
	let ctrl: IController = this.$ctrl;
	ctrl.$navigate('/catalog/item/show', coll.$selected, true);
}