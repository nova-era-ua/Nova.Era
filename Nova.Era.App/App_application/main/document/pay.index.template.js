define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("document/_common/index.module");
    const utils = require("std:utils");
    const template = {
        properties: {
            'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
            'TDocument.$CashAccount': cashAccountText
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function cashAccountText() {
        var _a, _b, _c, _d, _e, _f, _g;
        console.log(this, (_a = this.CashAccFrom) === null || _a === void 0 ? void 0 : _a.Id, (_b = this.CashAccFrom) === null || _b === void 0 ? void 0 : _b.Id);
        if (((_c = this.CashAccFrom) === null || _c === void 0 ? void 0 : _c.Id) && ((_d = this.CashAccFrom) === null || _d === void 0 ? void 0 : _d.Id))
            return `${this.CashAccFrom.$Name} -> ${this.CashAccTo.$Name}`;
        return ((_e = this.CashAccFrom) === null || _e === void 0 ? void 0 : _e.Id) ? (_f = this.CashAccFrom) === null || _f === void 0 ? void 0 : _f.$Name : (_g = this.CashAccTo) === null || _g === void 0 ? void 0 : _g.$Name;
    }
});
