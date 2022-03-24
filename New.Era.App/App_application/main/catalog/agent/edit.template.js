define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TAgent.$Title'() { return this.Id || '@[NewItem]'; }
        },
        validators: {
            'Agent.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
