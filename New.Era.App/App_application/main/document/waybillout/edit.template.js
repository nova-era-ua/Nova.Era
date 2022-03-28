define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TRoot.$TabNo': String
        },
        defaults: {
            'Document.Date': dateUtils.today(),
            'Document.Operation'() { return this.Operations[0]; }
        },
        commands: {
            apply
        }
    };
    exports.default = template;
    function apply() {
        alert('apply');
    }
});
