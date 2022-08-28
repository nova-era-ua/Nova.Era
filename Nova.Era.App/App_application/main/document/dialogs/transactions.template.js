define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TStoreTrans.$Dir'() { return this.Dir == -1 ? 'Видаток' : 'Прибуток'; },
            'TCashAcc.$Name'() { return this.Name || this.No; },
            'TCashAcc.$Title'() { return this.IsCash ? '@[CashAccount]' : '@[Account]'; }
        }
    };
    exports.default = template;
});
