define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/pay.module');
    const tmlutils = require("std:tmlutils");
    const template = {
        validators: {
            'Document.CashAccFrom': '@[Error.Required]'
        },
    };
    exports.default = tmlutils.mergeTemplate(base, template);
});
