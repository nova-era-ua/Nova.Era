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
            'Document.Operation'() { return this.Operations[0]; },
            'Document.Company'() { return this.Default.Company; },
            'Document.WhFrom'() { return this.Default.Warehouse; }
        },
        events: {
            'Document.Rows[].add'(rows, row) { row.Qty = 1; }
        },
        commands: {
            apply,
            unApply
        }
    };
    exports.default = template;
    function docSum() {
        return this.Rows.reduce((p, c) => p + c.Sum, 0);
    }
    async function apply() {
        let ctrl = this.$ctrl;
        let result = await ctrl.$invoke('apply', { Id: this.Document.Id });
        ctrl.$requery();
    }
    async function unApply() {
        let ctrl = this.$ctrl;
        let result = await ctrl.$invoke('unApply', { Id: this.Document.Id });
        ctrl.$requery();
    }
});
