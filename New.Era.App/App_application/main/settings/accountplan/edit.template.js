define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$TabMode': String,
            'TAccount.$Title'() { return this.Id ? this.Id : '@[NewItem]'; },
        },
        defaults: {
            'Account.ParentAccount'() { return this.Params.ParentAccount; }
        },
        validators: {
            'Account.Code': '@[Error.Required]',
            'Account.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
