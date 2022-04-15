define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("document/_common/index.module");
    const tmlUtils = require('std:tmlutils');
    const template = {
        properties: {
            'TBankAccount.$Name'() { return this.Name || this.AccountNo; },
            'TDocument.$BankAccount'() { var _a, _b, _c; return ((_a = this.BankAccFrom) === null || _a === void 0 ? void 0 : _a.Id) ? (_b = this.BankAccFrom) === null || _b === void 0 ? void 0 : _b.$Name : (_c = this.BankAccTo) === null || _c === void 0 ? void 0 : _c.$Name; },
            'TDocument.$CashAccount'() { var _a, _b, _c; return ((_a = this.CashAccFrom) === null || _a === void 0 ? void 0 : _a.Id) ? (_b = this.CashAccFrom) === null || _b === void 0 ? void 0 : _b.Name : (_c = this.CashAccTo) === null || _c === void 0 ? void 0 : _c.Name; }
        }
    };
    exports.default = tmlUtils.mergeTemplate(base, template);
});
