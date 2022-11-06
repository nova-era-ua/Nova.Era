const EDIT_URL = '/catalog/item/edit';

const template: Template = {
	properties: {
		'TRoot.$SelectedElem': selectedElem,
		'TRoot.$$Check': Boolean,
		'TItem.$HasVariants'() { return this.Variants.length > 0; }
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
	let ctrl: IController = this.$ctrl;
	let res = await ctrl.$showDialog(EDIT_URL, null);
	coll.$append(res);
	clearLazyElements(this.Groups, this.Groups.$selected);
}

async function edit(item) {
	let ctrl: IController = this.$ctrl;
	let res = await ctrl.$showDialog(EDIT_URL, { Id: item.Id });
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