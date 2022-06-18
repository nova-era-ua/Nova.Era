define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TAccount.$Title'() { return this.Id ? this.Id : '@[NewItem]'; },
        },
        validators: {
            'Account.Code': '@[Error.Required]',
            'Account.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
