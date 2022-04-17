define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TCashAcc.$Name'() { return this.Name || this.No; },
            'TCashAcc.$Title'() { return this.IsCash ? '@[CashAccount]' : '@[Account]'; }
        }
    };
    exports.default = template;
});
