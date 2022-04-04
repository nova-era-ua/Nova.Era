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
        events: {
            'app.document.saved': handleSaved,
            'app.document.apply': handleApply
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
        await ctrl.$showDialog(url, null, { Form: form.Id });
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
        await ctrl.$showDialog(url, { Id: doc.Id });
    }
    function clearFilter(elem) {
        elem.Id = 0;
        elem.Name = '';
    }
    function handleSaved(savedRoot) {
        const savedDoc = savedRoot.Document;
        let found = this.Documents.find(d => d.Id == savedDoc.Id);
        if (found)
            found.$merge(savedDoc);
        else {
            let newDoc = this.Documents.$append(savedDoc);
            newDoc.$select();
        }
    }
    function handleApply(elem) {
        let found = this.Documents.find(d => d.Id == elem.Id);
        if (!found)
            return;
        found.Done = elem.Done;
    }
});
