define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        options: {
            persistSelect: ['Documents']
        },
        properties: {
            'TDocument.$No'() { return this.SNo; },
            'TDocument.$Mark'() { return this.Done ? 'green' : undefined; },
        },
        events: {
            'app.document.saved': handleSaved,
            'app.document.apply': handleApply
        },
        commands: {
            clearFilter,
            create,
            editSelected: {
                exec: editSelected,
                canExec(docs) { return docs.$hasSelected; }
            },
            edit,
            delete: {
                exec: deleteDoc,
                canExec(doc) { return !doc.Done; },
                confirm: '@[Confirm.Delete.Element]'
            },
            copy: {
                exec: copyDoc,
                canExec(docs) { return docs.$hasSelected; },
            }
        }
    };
    exports.default = template;
    async function create(menu) {
        const ctrl = this.$ctrl;
        let url = `${menu.DocumentUrl}/edit`;
        await ctrl.$showDialog(url, null, { Operation: menu.Id });
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
        let url = `${doc.Operation.DocumentUrl}/edit`;
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
    async function deleteDoc(doc) {
        const ctrl = this.$ctrl;
        ctrl.$invoke('delete', { Id: doc.Id }, '/document/commands');
        doc.$remove();
    }
    function copyDoc(docs) {
        if (!docs.$hasSelected)
            return;
        const doc = docs.$selected;
        alert('copy document: ' + doc.Id);
    }
});
