define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TItem.$Title'() { return `@[Item] [${this.Id ? this.Id : '@[NewItem]'}]`; },
        },
        validators: {
            'Item.Name': '@[Error.Required]',
        },
        commands: {},
        delegates: {}
    };
    exports.default = template;
});
