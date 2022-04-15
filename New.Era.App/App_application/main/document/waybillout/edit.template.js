define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const tmlutils = require("std:tmlutils");
    const template = {
        defaults: {
            'Document.WhFrom'() { return this.Default.Warehouse; }
        },
        validators: {
            'Document.WhFrom': '@[Error.Required]'
        }
    };
    exports.default = tmlutils.mergeTemplate(base, template);
});
