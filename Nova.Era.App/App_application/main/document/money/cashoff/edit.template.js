define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/pay.module');
    const utils = require("std:utils");
    const template = {
        validators: {
            'Document.Agent': null,
            'Document.CashAccFrom': '@[Error.Required]',
            'Document.ItemRole': '@[Error.Required]'
        },
    };
    exports.default = utils.mergeTemplate(base, template);
});
