define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TCashAccount.$Id'() { return this.Id || '@[NewItem]'; },
            'TCurrency.$Display'() { return this.Short || this.Alpha3; }
        },
        defaults: {
            'CashAccount.Currency'() { return this.Params.Currency; },
            'CashAccount.Company'() { return this.Default.Company; },
            'CashAccount.ItemRole'() { return this.ItemRoles[0]; }
        },
        validators: {
            'CashAccount.Name': '@[Error.Required]',
            'CashAccount.Company': '@[Error.Required]',
            'CashAccount.Currency': '@[Error.Required]'
        }
    };
    exports.default = template;
});
