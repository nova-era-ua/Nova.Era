define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TIntegration.$Image': image
        }
    };
    exports.default = template;
    function image() {
        return `<img src="${this.Logo}" width="50px">`;
    }
});
