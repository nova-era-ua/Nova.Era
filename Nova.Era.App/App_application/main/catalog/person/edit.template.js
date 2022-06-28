define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TPerson.$Id'() { return this.Id || '@[NewItem]'; }
        },
        validators: {
            'Person.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
