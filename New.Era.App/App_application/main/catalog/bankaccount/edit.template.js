define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TBankAccount.$Id'() { return this.Id || '@[NewItem]'; }
        },
        validators: {
            'BankAccount.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
