define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TBrand.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Brand.Name': '@[Error.Required]',
        }
    };
    exports.default = template;
});
