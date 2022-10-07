define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TContact.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Contact.Name': '@[Error.Required]',
        },
        defaults: {}
    };
    exports.default = template;
});
