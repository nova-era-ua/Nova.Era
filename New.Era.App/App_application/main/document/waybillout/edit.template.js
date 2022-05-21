define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$BrowseItemArg'() { return { IsStock: 'T', PriceKind: this.Document.PriceKind.Id }; }
        },
        defaults: {
            'Document.WhFrom'() { return this.Default.Warehouse; }
        },
        validators: {
            'Document.WhFrom': '@[Error.Required]'
        },
        events: {
            'Document.Contract.change': contractChange,
            'Document.StockRows[].Item.change': itemChange,
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function contractChange(doc, contract) {
        doc.PriceKind.$set(contract.PriceKind);
    }
    function itemChange(row, val) {
        base.events['Document.StockRows[].Item.change'].call(this, row, val);
        row.Price = val.Price;
    }
});
