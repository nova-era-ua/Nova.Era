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
        }
    };
    exports.default = utils.mergeTemplate(base, template);
});
