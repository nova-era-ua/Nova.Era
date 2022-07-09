define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/pay.module');
    const utils = require("std:utils");
    const template = {
        validators: {
            'Document.CashAccTo': '@[Error.Required]',
            'Document.CashAccFrom': '@[Error.Required]',
            'Document.Agent': ''
        },
    };
    exports.default = utils.mergeTemplate(base, template);
});
