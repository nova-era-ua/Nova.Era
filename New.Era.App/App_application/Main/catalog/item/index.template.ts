
import { TRoot, TFolder, TItem, TItems, TFolders } from './index';

let savedFolderId: number;

const template: Template = {
	properties: {
		'TRoot.$Filter': String,
		'TRoot.$IsSeachFolder'(this: TRoot) { return this.Folders.$selected.$IsSearch; },
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
	events: {
		'Model.load': modelLoad,
		'Root.$Filter.change': filterChange,
		'Folders[].select': selectionChange
	},
	commands: {
		clearFilter,
		createRoot,
		createFolder,
		gotoFolder
	}
}

export default template;

function modelLoad(this: TRoot) {
	// search results folder
	let srFolder = this.Folders.$find(x => x.Id == -1);
	createModelInfo(this, srFolder.Children);
}

function createModelInfo(root: TRoot, arr: TItems): IModelInfo {

	/* We have to create ModelInfo for children elements in search folder (Id=-1).
	 * There is no model info before first call, create it with database defaults.
	 */

	return root.$createModelInfo(arr, {
		Filter: {
			Fragment: null
		},
		PageSize: 10,
		Offset: 0,
		SortDir: SortDir.asc,
		SortOrder: 'name'
	});
}

function clearFilter(this: TRoot): void {
	this.$Filter = '';
}

function selectionChange(this: TRoot, folders: TFolders): void {
	let sel = folders.$selected
	if (sel && sel.$IsFolder) {
		savedFolderId = 0;
		this.$Filter = '';
	}
}

function filterChange(this: TRoot, elem: TRoot, newVal: string, oldVal: string, propName: string): void {

	const folders = elem.Folders;
	const ctrl = this.$ctrl;

	// searh folder
	let srFolder = folders.$find(x => x.Id == -1);

	if (newVal) {
		if (!savedFolderId) {
			let sel = folders.$selected;
			savedFolderId = sel ? sel.Id : 0;
		}
		srFolder.$select(folders);

		srFolder.Children.$ModelInfo.Filter.Fragment = newVal;
		ctrl.$reload(srFolder.Children);
	} else {
		// reset filter
		srFolder.Children.$resetLazy();
		if (savedFolderId) {
			// вернем сохраненную папку
			let frItem = folders.$find(x => x.Id === savedFolderId);
			if (frItem)
				frItem.$select(folders);
		}
		savedFolderId = 0;
	}
}

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

async function gotoFolder(this: TRoot, item: TItem) {
	const ctrl = this.$ctrl;

	function findItem(arr: TItems) {
		let itm = arr.$find(a => a.Id == item.Id);
		if (itm) {
			itm.$select();
			return itm;
		}
		return null;
	}

	async function findItemOffset(folder, mi): Promise<number> {
		folder.Children.$lockUpdate(true);
		let res = await ctrl.$invoke('findIndex', { Id: item.Id, Parent: folder.Id, Order: mi.SortOrder, Dir: mi.SortDir });
		folder.Children.$lockUpdate(false);
		if (res && res.Result) {
			let ix: number = res.Result.RowNo;
			// ix index in the list. It is visible
			let pageNo = Math.floor(ix / mi.PageSize);
			return pageNo * mi.PageSize;
		}
		return -1;
	}

	// goto to parent folder in tree
	const parentFolder = item.ParentFolder.Id;
	const folders = this.Folders;

	let fld: any = folders.$find(itm => itm.Id == parentFolder);
	let path = [];
	if (fld != null) {
		// folder found. Collect parents into array
		while (fld && fld != this) {
			path.push(fld.Id);
			fld = fld.$parent.$parent;
		}
		path = path.reverse();
	} else {
		// folder not found. lets go to server and get path
		let result = await ctrl.$invoke('getPath', { Id: item.ParentFolder.Id, Root: this.Hierarchy.Id });
		if (result && result.Result)
			path = result.Result.map(x => x.Id);
	}

	if (!path.length) return; // path not found, return

	// select folder, then item
	let l1: TFolder = folders.$find(itm => itm.Id == path[0]);
	let selFolder: TFolder = await l1.$selectPath<TFolder>(path, (itm, num) => itm.Id === num);
	if (!selFolder) return; // there is no element.
	selFolder.$select(folders);
	let ch = selFolder.Children;
	if (ch.$loaded) {
		let ag = findItem(ch);
		if (!ag) {
			ch.$resetLazy(); // reset old content
			let mi = createModelInfo(this, ch);
			let offset = await findItemOffset(selFolder, mi);
			if (offset == -1)
				return;
			mi.Offset = offset;
			await ch.$reload();
			findItem(ch);
		}
	}
	else {
		// children elements not loaded. Find page for this
		let mi = createModelInfo(this, ch);
		let offset = await findItemOffset(selFolder, mi);
		if (offset == -1)
			return;
		mi.Offset = offset;
		await ch.$reload();
		findItem(ch);
	}
}

