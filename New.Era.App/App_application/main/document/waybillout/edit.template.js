define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        defaults: {
            'Document.WhFrom'() { return this.Default.Warehouse; }
        },
        validators: {
            'Document.WhFrom': '@[Error.Required]'
        },
        events: {
            'Document.Contract.change': contractChange
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function contractChange(doc, contract) {
        doc.PriceKind.$set(contract.PriceKind);
    }
});
