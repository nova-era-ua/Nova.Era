define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
            'TAccount.$Icon'() { return 'account-folder'; }
        }
    };
    exports.default = template;
});
