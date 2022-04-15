define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TCashAccount.$Id'() { return this.Id || '@[NewItem]'; }
        },
        defaults: {
            'CashAccount.Currency'() { return this.Params.Currency; }
        },
        validators: {
            'CashAccount.Name': '@[Error.Required]',
            'CashAccount.Company': '@[Error.Required]',
            'CashAccount.Currency': '@[Error.Required]'
        }
    };
    exports.default = template;
});
