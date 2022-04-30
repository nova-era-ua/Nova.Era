define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TContract.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Contract.Company': '@[Error.Required]',
            'Contract.Agent': '@[Error.Required]'
        },
        defaults: {
            'Contract.Date': dateUtils.today(),
            'Contract.Company'() { return this.Default.Company; }
        }
    };
    exports.default = template;
});
