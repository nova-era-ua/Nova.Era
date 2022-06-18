define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const utils = require("std:utils");
    const base = require('/document/_common/common.module');
    const template = {
        properties: {
            'TRoot.$$TabNo': String,
            'TRow.Sum': {
                get() { return this.Price * this.Qty; },
                set(val) { this.Qty = val / this.Price; }
            },
            'TRoot.$StockItemRoles'() { return this.ItemRoles.filter(r => r.IsStock); },
            'TDocument.Sum': docSum,
            'TDocument.$StockSum': stockSum,
            'TDocument.$ServiceSum': serviceSum,
            'TDocument.$StockESum': stockESum,
        },
        validators: {
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
        commands: {}
    };
    exports.default = utils.mergeTemplate(base, template);
    function docSum() {
        return this.$StockSum + this.$ServiceSum;
    }
    function stockSum() {
        return this.StockRows.reduce((p, c) => p + c.Sum, 0);
    }
    function stockESum() {
        return this.StockRows.reduce((p, c) => p + c.ESum, 0);
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
        let result = await ctrl.$invoke('findArticle', {
            Text: val,
            PriceKind: this.Document.PriceKind.Id,
            Date: this.Document.Date
        }, '/catalog/item');
        (result === null || result === void 0 ? void 0 : result.Item) ? item.$merge(result.Item) : item.$empty();
    }
});
