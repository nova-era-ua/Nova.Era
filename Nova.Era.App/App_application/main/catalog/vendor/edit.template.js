define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TVendor.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Vendor.Name': '@[Error.Required]',
        }
    };
    exports.default = template;
});
