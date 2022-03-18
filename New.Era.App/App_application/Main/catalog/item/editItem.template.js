define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        validators: {
            'Item.Name': "notBlank"
        },
        defaults: {
            "Item.ParentFolder"() { return this.ParentFolder; }
        }
    };
    exports.default = template;
});
