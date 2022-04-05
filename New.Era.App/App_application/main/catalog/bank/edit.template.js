define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TBank.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Bank.Name': '@[Error.Required]',
            'Bank.BankCode': '@[Error.Required]',
        }
    };
    exports.default = template;
});
