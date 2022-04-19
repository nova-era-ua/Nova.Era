define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        commands: {
            clearFilter
        }
    };
    exports.default = template;
    function clearFilter(filter) {
        filter.Id = -1;
        filter.Name = '';
    }
});
