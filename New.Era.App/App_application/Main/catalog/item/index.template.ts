
import { TRoot, TFolder } from 'index.d';


const template: Template = {
	properties: {
		'TRoot.$Filter': String,
		'TFolder.$IsSearch'(this: TFolder): boolean { return this.Id === -1; },
		'TFolder.$IsFolder'(this: TFolder): boolean { return this.Id !== -1; },
		'TFolder.$IsVisible'(this: TFolder): boolean {
			return this.$IsFolder || !!this.$root.$Filter;
		},
		'TRoot.$ParentFolderData'(this: TRoot): object {
			let sel: TFolder = this.Folders.$selected;
			return sel ? { Parent: sel.Id } : {};
		}
	},
	commands: {
		createRoot,
		createFolder
	}
}

export default template;

async function createRoot(this: TRoot, parent: TFolder) {
	const ctrl = this.$ctrl;
	// create folder. Parent = 1
	let elem = await ctrl.$showDialog('/catalog/item/editFolder', { Id: 0 }, { Parent: this.Hierarchy.Id });
	// and prepend it into children before search folder
	let searchFolder = this.Folders.$find(x => x.Id === -1);
	let fld = this.Folders.$insert(elem, InsertTo.above, searchFolder);
	// and select it
	fld.$select(this.Folders);
}

async function createFolder(this: TRoot, parent: TFolder) {
	const ctrl = this.$ctrl;

	// cannot be created in the search result folder
	if (!parent || parent.$IsSearch) return;

	// expand the parent node first
	await ctrl.$expand(parent, 'SubItems', true);

	// create new folder
	let elem = await ctrl.$showDialog('/catalog/item/editFolder', { Id: 0 }, { Parent: parent.Id });
	// append it into children
	let fld = parent.SubItems.$append(elem);
	// select it
	fld.$select(this.Folders);
}