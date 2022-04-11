define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TReport.$Url'() { return this.Url + "/" + this.Id; }
        }
    };
    exports.default = template;
});
