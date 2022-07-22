define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("document/_common/index.module");
    const utils = require("std:utils");
    const template = {
        properties: {
            'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
            'TDocument.$SumDir': sumDir,
            'TDocument.$CashAccount': cashAccountText
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function cashAccountText() {
        var _a, _b, _c, _d, _e;
        if (((_a = this.CashAccFrom) === null || _a === void 0 ? void 0 : _a.Id) && ((_b = this.CashAccTo) === null || _b === void 0 ? void 0 : _b.Id))
            return `${this.CashAccFrom.$Name} -> ${this.CashAccTo.$Name}`;
        return ((_c = this.CashAccFrom) === null || _c === void 0 ? void 0 : _c.Id) ? (_d = this.CashAccFrom) === null || _d === void 0 ? void 0 : _d.$Name : (_e = this.CashAccTo) === null || _e === void 0 ? void 0 : _e.$Name;
    }
    function sumDir() {
        var _a, _b, _c;
        if (((_a = this.CashAccFrom) === null || _a === void 0 ? void 0 : _a.Id) && ((_b = this.CashAccTo) === null || _b === void 0 ? void 0 : _b.Id))
            return 0;
        return ((_c = this.CashAccFrom) === null || _c === void 0 ? void 0 : _c.Id) ? -1 : 1;
    }
});
