define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TBankAccount.$Id'() { return this.Id || '@[NewItem]'; }
        },
        defaults: {
            'BankAccount.Currency'() { return this.Params.Currency; }
        },
        validators: {
            'BankAccount.AccountNo': '@[Error.Required]',
            'BankAccount.Company': '@[Error.Required]',
            'BankAccount.Currency': '@[Error.Required]'
        }
    };
    exports.default = template;
});
