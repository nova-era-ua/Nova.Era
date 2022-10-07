define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TLead.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Lead.Name': '@[Error.Required]',
            'Lead.Stage': '@[Error.Required]'
        },
        defaults: {
            'Lead.Stage'() { return this.Stages.length > 0 ? this.Stages[0] : null; }
        }
    };
    exports.default = template;
});
