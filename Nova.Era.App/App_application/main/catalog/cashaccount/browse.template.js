define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
        },
    };
    exports.default = template;
});
