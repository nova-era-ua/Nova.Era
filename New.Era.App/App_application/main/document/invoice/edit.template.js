define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        defaults: {
            'Document.Operation'() { return this.Operations[0]; },
            'Document.Date': dateUtils.today(),
        },
        properties: {},
        commands: {}
    };
    exports.default = template;
});
