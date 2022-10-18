define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const utils = require('std:utils');
    const du = utils.date;
    const template = {
        properties: {
            'TRoot.$Today': todayCount
        }
    };
    exports.default = template;
    function todayCount() {
        return 22;
    }
});
