define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$IntVal': Number
        },
        delegates: {
            filter
        }
    };
    exports.default = template;
    function filter(elem, filter) {
        return elem.Code.toLowerCase().indexOf(filter.Fragment.toLowerCase()) !== -1;
    }
});
