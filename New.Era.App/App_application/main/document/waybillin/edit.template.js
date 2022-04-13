define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const tmlutils = require("std:tmlutils");
    const template = tmlutils.mergeTemplate(base, {
        defaults: {
            'Document.WhTo'() { return this.Default.Warehouse; }
        },
        validators: {
            'Document.WhTo': '@[Error.Required]'
        }
    });
    console.dir(template);
    exports.default = template;
});
