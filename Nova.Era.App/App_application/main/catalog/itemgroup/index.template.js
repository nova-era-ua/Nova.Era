define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        options: {},
        events: {
            'Model.load': modelLoad
        },
        commands: {
            addItem,
            editItem: {
                exec: editItem,
                canExec() { return !!this.Groups.$selected; }
            },
            addHierarchy,
            deleteItem: {
                exec: deleteItem,
                canExec(elem) { var _a; return elem && !elem.HasItems && !((_a = elem.Items) === null || _a === void 0 ? void 0 : _a.length); },
                confirm: '@[Confirm.Delete.Element]'
            }
        }
    };
    exports.default = template;
    function modelLoad() {
    }
    async function addItem() {
        if (this.Groups.$isEmpty) {
            addHierarchy.call(this);
            return;
        }
        let parent = this.Groups.$selected;
        if (!parent)
            return;
        const ctrl = this.$ctrl;
        await ctrl.$expand(parent, 'Items', true);
        let group = await ctrl.$showDialog('/catalog/itemgroup/edit', null, { Parent: parent.Id });
        let newgroup = parent.Items.$append(group);
        newgroup.$select(this.Groups);
    }
    async function editItem() {
        let elem = this.Groups.$selected;
        if (!elem)
            return;
        const ctrl = this.$ctrl;
        let url = elem.IsRoot ? '/catalog/itemgroup/edithie' : '/catalog/itemgroup/edit';
        let group = await ctrl.$showDialog(url, { Id: elem.Id });
        elem.$merge(group);
    }
    async function addHierarchy() {
        const ctrl = this.$ctrl;
        let group = await ctrl.$showDialog('/catalog/itemgroup/edithie', null);
        group.Icon = 'folders-outline';
        let newhie = this.Groups.$append(group);
        newhie.$select(this.Groups);
    }
    async function deleteItem(item) {
        if (!item)
            return;
        if (item.HasItems || item.Items.length)
            return;
        const ctrl = this.$ctrl;
        await ctrl.$invoke('deleteItem', { Id: item.Id });
        item.$remove();
    }
});
