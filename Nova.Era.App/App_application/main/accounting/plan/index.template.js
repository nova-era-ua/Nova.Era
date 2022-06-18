define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const tu = require('std:utils').text;
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TRoot.$Search': String,
            'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
            'TAccount.$Icon'() { return this.IsFolder ? 'account-folder' : 'account'; },
            'TAccount.$IsPlan'() { return this.Plan === 0; }
        },
        events: {
            'Root.$Search.change': searchAccount,
        },
        commands: {
            editDocument,
            editSelectedDocument
        }
    };
    exports.default = template;
    function searchAccount(root, text) {
        if (!text)
            return;
        let found = root.Accounts.$find(el => el.Code.indexOf(text) === 0 || tu.contains(el.Name, text));
        if (found)
            found.$select(root.Accounts);
        else
            root.$Search = '';
    }
    async function editSelectedDocument(docs) {
        if (!docs)
            return;
        let doc = docs.$selected;
        if (!doc)
            return;
        const ctrl = this.$ctrl;
        let url = `/document/${doc.Operation.Form}/edit`;
        await ctrl.$showDialog(url, { Id: doc.Id });
    }
    async function editDocument(doc) {
        if (!doc)
            return;
        const ctrl = this.$ctrl;
        let url = `/document/${doc.Operation.Form}/edit`;
        await ctrl.$showDialog(url, { Id: doc.Id });
    }
});
