define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/pay.module');
    const tmlutils = require("std:tmlutils");
    const template = {
        properties: {
            'TBankAccount.$Name'() { return this.Name || this.AccountNo; }
        },
        validators: {
            'Document.BankAccFrom': '@[Error.Required]'
        }
    };
    exports.default = tmlutils.mergeTemplate(base, template);
});
