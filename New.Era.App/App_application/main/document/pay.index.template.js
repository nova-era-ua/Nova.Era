define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("document/_common/index.module");
    const utils = require("std:utils");
    const template = {
        properties: {
            'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
            'TDocument.$CashAccount'() { var _a, _b, _c; return ((_a = this.CashAccFrom) === null || _a === void 0 ? void 0 : _a.Id) ? (_b = this.CashAccFrom) === null || _b === void 0 ? void 0 : _b.$Name : (_c = this.CashAccTo) === null || _c === void 0 ? void 0 : _c.$Name; }
        }
    };
    exports.default = utils.mergeTemplate(base, template);
});
