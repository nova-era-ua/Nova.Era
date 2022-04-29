define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TAccKind.$Id'() { return this.Id || '@[NewItem]'; },
        },
        defaults: {},
        validators: {
            'AccKind.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
