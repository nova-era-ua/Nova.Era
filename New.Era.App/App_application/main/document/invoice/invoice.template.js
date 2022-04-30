define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$$Scan': String
        },
        events: {
            'Root.$$Scan.change': scanChange
        },
        validators: {
            'Document.StockRows[].Qty': '@[Error.Required]'
        },
        commands: {}
    };
    exports.default = utils.mergeTemplate(base, template);
    function scanChange() {
        alert('scan');
    }
});
