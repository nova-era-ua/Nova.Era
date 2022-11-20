define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TOption.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Option.Name': '@[Error.Required]'
        },
        defaults: {}
    };
    exports.default = template;
});
