define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        options: {
            persistSelect: ['Documents']
        },
        properties: {
            'TDocument.$Mark'() { return this.Done ? 'green' : undefined; },
            'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name; }
        },
        commands: {
            clearFilter,
            create,
            editSelected,
            edit
        }
    };
    exports.default = template;
    async function create(form) {
        const ctrl = this.$ctrl;
        let url = `/document/${form.Id}/edit`;
        let docsrc = await ctrl.$showDialog(url, null, { Form: form.Id });
        let doc = this.Documents.$append(docsrc);
        doc.$select();
    }
    function editSelected(docs) {
        let doc = docs.$selected;
        if (!doc)
            return;
        edit.call(this, doc);
    }
    async function edit(doc) {
        if (!doc)
            return;
        const ctrl = this.$ctrl;
        let url = `/document/${doc.Operation.Form}/edit`;
        let rdoc = await ctrl.$showDialog(url, { Id: doc.Id });
        doc.$merge(rdoc);
    }
    function clearFilter(elem) {
        elem.Id = 0;
        elem.Name = '';
    }
});
