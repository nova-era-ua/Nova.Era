define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TRoot.$$TabNo': String,
            'TRow.Sum': {
                get() { return this.Price * this.Qty; },
                set(val) { this.Qty = val / this.Price; }
            },
            'TDocument.Sum': docSum,
            'TDocument.$StockSum': stockSum,
            'TDocument.$ServiceSum': serviceSum,
            'TDocument.$CompanyAgentArg'() { return { Company: this.Company.Id, Agent: this.Agent.Id }; }
        },
        defaults: {
            'Document.Date': dateUtils.today(),
            'Document.Operation'() { return this.Operations.find(o => o.Id === this.Params.Operation); },
            'Document.Company'() { return this.Default.Company; },
            'Document.RespCenter'() { return this.Default.RespCenter; }
        },
        validators: {
            'Document.Company': '@[Error.Required]',
            'Document.Agent': '@[Error.Required]',
            'Document.StockRows[].Item': '@[Error.Required]',
            'Document.ServiceRows[].Item': '@[Error.Required]',
        },
        events: {
            'Document.StockRows[].add'(rows, row) { row.Qty = 1; },
            'Document.StockRows[].Item.change': itemChange,
            'Document.StockRows[].Item.Article.change': articleChange,
            'Document.ServiceRows[].add'(rows, row) { row.Qty = 1; },
            'Document.ServiceRows[].Item.change': itemChange,
            'Document.ServiceRows[].Item.Article.change': articleChange
        },
        commands: {
            apply,
            unApply
        }
    };
    exports.default = template;
    function docSum() {
        return this.$StockSum + this.$ServiceSum;
    }
    function stockSum() {
        return this.StockRows.reduce((p, c) => p + c.Sum, 0);
    }
    function serviceSum() {
        return this.ServiceRows.reduce((p, c) => p + c.Sum, 0);
    }
    function itemChange(row, val) {
        row.Unit = val.Unit;
        row.ItemRole = val.Role;
    }
    async function articleChange(item, val) {
        if (!val) {
            item.$empty();
            return;
        }
        ;
        const ctrl = this.$ctrl;
        let result = await ctrl.$invoke('findArticle', { Text: val }, '/catalog/item');
        (result === null || result === void 0 ? void 0 : result.Item) ? item.$merge(result.Item) : item.$empty();
    }
    async function apply() {
        const ctrl = this.$ctrl;
        await ctrl.$invoke('apply', { Id: this.Document.Id });
        ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: true });
        ctrl.$requery();
    }
    async function unApply() {
        let ctrl = this.$ctrl;
        await ctrl.$invoke('unApply', { Id: this.Document.Id });
        ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: false });
        ctrl.$requery();
    }
});
