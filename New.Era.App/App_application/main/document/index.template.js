define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {},
        commands: {
            create,
            editSelected,
            edit
        }
    };
    exports.default = template;
    async function create() {
        const ctrl = this.$ctrl;
        let sel = this.Operations.$selected;
        if (!sel)
            return;
        let url = `/document/${sel.Form.Url}/edit`;
        let operation = await ctrl.$showDialog(url, null, { Operation: sel.Id });
        console.dir(operation);
    }
    function editSelected(docs) {
        alert('editSelected');
    }
    async function edit(doc) {
        const ctrl = this.$ctrl;
        if (!doc)
            return;
        let url = `/document/${doc.FormUrl}/edit`;
        let rdoc = await ctrl.$showDialog(url, { Id: doc.Id });
        console.dir(rdoc);
    }
});
