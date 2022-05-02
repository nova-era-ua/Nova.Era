define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TCostItem.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'CostItem.Name': '@[Error.Required]',
        }
    };
    exports.default = template;
});
