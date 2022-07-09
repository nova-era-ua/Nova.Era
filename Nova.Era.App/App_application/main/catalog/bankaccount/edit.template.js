define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TBankAccount.$Id'() { return this.Id || '@[NewItem]'; }
        },
        defaults: {
            'BankAccount.Currency'() { return this.Params.Currency; },
            'BankAccount.Company'() { return this.Default.Company; },
            'BankAccount.ItemRole'() { return this.ItemRoles[0]; }
        },
        validators: {
            'BankAccount.AccountNo': '@[Error.Required]',
            'BankAccount.Company': '@[Error.Required]',
            'BankAccount.Currency': '@[Error.Required]'
        },
        events: {
            'BankAccount.AccountNo.change': bankAccountChange
        }
    };
    exports.default = template;
    function bankAccountChange(ba, accno) {
        console.dir(accno);
    }
});
