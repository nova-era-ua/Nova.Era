define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/pay.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TCashAccount.$Name'() { return this.Name || this.AccountNo; }
        },
        validators: {
            'Document.CashAccTo': '@[Error.Required]'
        }
    };
    exports.default = utils.mergeTemplate(base, template);
});
