define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        defaults: {
            'Document.WhTo'() { return this.Default.Warehouse; }
        },
        validators: {
            'Document.WhTo': '@[Error.Required]'
        },
        events: {
            'Document.ServiceRows[].Item.change': itemChange,
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function itemChange(row, val) {
        base.events['Document.ServiceRows[].Item.change'].call(this, row, val);
        row.CostItem = val.CostItem;
    }
});
