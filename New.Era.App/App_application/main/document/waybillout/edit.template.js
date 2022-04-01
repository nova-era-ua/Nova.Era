define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TRoot.$$TabNo': String,
            'TRow.Sum'() { return this.Price * this.Qty; },
            'TDocument.Sum': docSum
        },
        defaults: {
            'Document.Date': dateUtils.today(),
            'Document.Operation'() { return this.Operations[0]; }
        },
        events: {
            'Document.Rows[].add'(rows, row) { row.Qty = 1; }
        },
        commands: {
            apply
        }
    };
    exports.default = template;
    function docSum() {
        return this.Rows.reduce((p, c) => p + c.Sum, 0);
    }
    async function apply() {
        let ctrl = this.$ctrl;
        let result = await ctrl.$invoke('apply', { Id: this.Document.Id });
        alert(JSON.stringify(result));
        ctrl.$requery();
    }
});
