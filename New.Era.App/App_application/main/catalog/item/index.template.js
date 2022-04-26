define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const EDIT_URL = '/catalog/item/edit';
    const template = {
        properties: {
            'TRoot.$SelectedElem': selectedElem,
        },
        events: {},
        commands: {
            create,
            edit,
            editSelected: {
                exec: editSelected,
                canExec(coll) { return coll.$hasSelected; }
            }
        }
    };
    exports.default = template;
    function selectedElem() {
        var _a;
        let sel = this.Groups.$selected;
        if (!sel)
            return undefined;
        return (_a = sel.Elements.$selected) === null || _a === void 0 ? void 0 : _a.Id;
    }
    function clearLazyElements(items, sel) {
        items.forEach(el => {
            if (el !== sel)
                el.Elements.$resetLazy();
            clearLazyElements(el.Items, sel);
        });
    }
    async function create(coll) {
        let ctrl = this.$ctrl;
        let res = await ctrl.$showDialog(EDIT_URL, null);
        coll.$append(res);
        clearLazyElements(this.Groups, this.Groups.$selected);
    }
    async function edit(item) {
        let ctrl = this.$ctrl;
        let res = await ctrl.$showDialog(EDIT_URL, { Id: item.Id });
        item.$merge(res);
        clearLazyElements(this.Groups, this.Groups.$selected);
    }
    async function editSelected(coll) {
        if (!coll.$hasSelected)
            return;
        await edit.call(this, coll.$selected);
    }
});
