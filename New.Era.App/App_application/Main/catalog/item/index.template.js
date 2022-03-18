define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$Filter': String,
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
        commands: {
            createRoot,
            createFolder
        }
    };
    exports.default = template;
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
});
