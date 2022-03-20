define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    let savedFolderId;
    const template = {
        properties: {
            'TRoot.$Filter': String,
            'TRoot.$IsSeachFolder'() { return this.Folders.$selected.$IsSearch; },
            'TFolder.$IsSearch'() { return this.Id === -1; },
            'TFolder.$IsFolder'() { return this.Id !== -1; },
            'TFolder.$IsVisible'() {
                return this.$IsFolder || !!this.$root.$Filter;
            },
            'TRoot.$ParentFolderData'() {
                let sel = this.Folders.$selected;
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
            gotoFolder,
            deleteFolder: {
                exec: deleteFolder,
                canExec: canDeleteFolder,
                confirm: '@[Confirm.Delete.Folder]'
            },
            deleteItem: {
                exec: deleteItem,
                canExec(items) { return !!(items === null || items === void 0 ? void 0 : items.$selected); },
                confirm: '@[Confirm.Delete.Element]'
            }
        }
    };
    exports.default = template;
    function modelLoad() {
        let srFolder = this.Folders.$find(x => x.Id == -1);
        createModelInfo(this, srFolder.Children);
    }
    function createModelInfo(root, arr) {
        return root.$createModelInfo(arr, {
            Filter: {
                Fragment: null
            },
            PageSize: 10,
            Offset: 0,
            SortDir: "asc",
            SortOrder: 'name'
        });
    }
    function clearFilter() {
        this.$Filter = '';
    }
    function selectionChange(folders) {
        let sel = folders.$selected;
        if (sel && sel.$IsFolder) {
            savedFolderId = 0;
            this.$Filter = '';
        }
    }
    function filterChange(elem, newVal, oldVal, propName) {
        const folders = elem.Folders;
        const ctrl = this.$ctrl;
        let srFolder = folders.$find(x => x.Id == -1);
        if (newVal) {
            if (!savedFolderId) {
                let sel = folders.$selected;
                savedFolderId = sel ? sel.Id : 0;
            }
            srFolder.$select(folders);
            srFolder.Children.$ModelInfo.Filter.Fragment = newVal;
            ctrl.$reload(srFolder.Children);
        }
        else {
            srFolder.Children.$resetLazy();
            if (savedFolderId) {
                let frItem = folders.$find(x => x.Id === savedFolderId);
                if (frItem)
                    frItem.$select(folders);
            }
            savedFolderId = 0;
        }
    }
    async function createRoot(parent) {
        const ctrl = this.$ctrl;
        let elem = await ctrl.$showDialog('/catalog/item/editFolder', { Id: 0 }, { Parent: this.Hierarchy.Id });
        let searchFolder = this.Folders.$find(x => x.Id === -1);
        let fld = this.Folders.$insert(elem, "above", searchFolder);
        fld.$select(this.Folders);
    }
    async function createFolder(parent) {
        const ctrl = this.$ctrl;
        if (!parent || parent.$IsSearch)
            return;
        await ctrl.$expand(parent, 'SubItems', true);
        let elem = await ctrl.$showDialog('/catalog/item/editFolder', { Id: 0 }, { Parent: parent.Id });
        let fld = parent.SubItems.$append(elem);
        fld.$select(this.Folders);
    }
    async function gotoFolder(item) {
        const ctrl = this.$ctrl;
        function findItem(arr) {
            let itm = arr.$find(a => a.Id == item.Id);
            if (itm) {
                itm.$select();
                return itm;
            }
            return null;
        }
        async function findItemOffset(folder, mi) {
            folder.Children.$lockUpdate(true);
            let res = await ctrl.$invoke('findIndex', { Id: item.Id, Parent: folder.Id, Order: mi.SortOrder, Dir: mi.SortDir });
            folder.Children.$lockUpdate(false);
            if (res && res.Result) {
                let ix = res.Result.RowNo;
                let pageNo = Math.floor(ix / mi.PageSize);
                return pageNo * mi.PageSize;
            }
            return -1;
        }
        const parentFolder = item.ParentFolder.Id;
        const folders = this.Folders;
        let fld = folders.$find(itm => itm.Id == parentFolder);
        let path = [];
        if (fld != null) {
            while (fld && fld != this) {
                path.push(fld.Id);
                fld = fld.$parent.$parent;
            }
            path = path.reverse();
        }
        else {
            let result = await ctrl.$invoke('getPath', { Id: item.ParentFolder.Id, Root: this.Hierarchy.Id });
            if (result && result.Result)
                path = result.Result.map(x => x.Id);
        }
        if (!path.length)
            return;
        let l1 = folders.$find(itm => itm.Id == path[0]);
        let selFolder = await l1.$selectPath(path, (itm, num) => itm.Id === num);
        if (!selFolder)
            return;
        selFolder.$select(folders);
        let ch = selFolder.Children;
        if (ch.$loaded) {
            let ag = findItem(ch);
            if (!ag) {
                ch.$resetLazy();
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
            let mi = createModelInfo(this, ch);
            let offset = await findItemOffset(selFolder, mi);
            if (offset == -1)
                return;
            mi.Offset = offset;
            await ch.$reload();
            findItem(ch);
        }
    }
    function canDeleteFolder(folder) {
        var _a;
        return (folder === null || folder === void 0 ? void 0 : folder.$IsFolder) && !(folder === null || folder === void 0 ? void 0 : folder.HasSubItems) && ((_a = folder === null || folder === void 0 ? void 0 : folder.Children) === null || _a === void 0 ? void 0 : _a.$isEmpty);
    }
    async function deleteFolder(folder) {
        if (!canDeleteFolder(folder))
            return;
        let rootFolder = this.Folders;
        await this.$ctrl.$invoke('deleteFolder', { Id: folder.Id });
        folder.$remove();
        this.$ctrl.$defer(() => {
            var _a;
            if ((_a = rootFolder.$selected) === null || _a === void 0 ? void 0 : _a.$IsSearch) {
                if (rootFolder.length > 1)
                    rootFolder[rootFolder.length - 2].$select();
            }
        });
    }
    async function deleteItem(arr) {
        const ctrl = this.$ctrl;
        if (!arr || !arr.$selected)
            return;
        await ctrl.$invoke('deleteItem', { Id: arr.$selected.Id });
        arr.$selected.$remove();
    }
});
