define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        options: {
            persistSelect: ['Forms']
        },
        commands: {
            editSelected: {
                exec: editSelected,
                canExec(arr) { return arr.$hasSelected; }
            }
        }
    };
    exports.default = template;
    async function editSelected(arr) {
        const ctrl = this.$ctrl;
        let url = '/catalog/docstate/edit';
        let sel = arr.$selected;
        if (!sel)
            return;
        await ctrl.$showDialog(url, sel);
        ctrl.$reload();
    }
});
