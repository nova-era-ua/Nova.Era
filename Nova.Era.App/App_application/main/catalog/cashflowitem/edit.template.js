define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TCashFlowItem.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'CashFlowItem.Name': '@[Error.Required]',
        }
    };
    exports.default = template;
});
