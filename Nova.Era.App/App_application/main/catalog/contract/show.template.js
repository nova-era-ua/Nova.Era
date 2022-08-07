define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String
        },
        commands: {
            editDocument
        }
    };
    exports.default = template;
    async function editDocument(doc) {
        if (!doc)
            return;
        const ctrl = this.$ctrl;
        let url = `${doc.Operation.DocumentUrl}/edit`;
        await ctrl.$showDialog(url, { Id: doc.Id });
    }
});
