define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TPriceKind.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'PriceKind.Name': '@[Error.Required]',
        }
    };
    exports.default = template;
});
