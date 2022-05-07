define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        commands: {
            clearFilter
        }
    };
    exports.default = template;
    function clearFilter(elem) {
        elem.Id = 0;
        elem.Name = '';
    }
});
