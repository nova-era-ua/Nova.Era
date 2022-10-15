define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TContact.$Id'() { return this.Id ? this.Id : '@[NewItem]'; },
            'TContact.$AddressUrl'() { return `https://www.google.com/maps/search/${this.Address.replace(/\.|\,/g, ' ')}`; },
            'TContact.$HasAddress'() { return !!this.Address; },
            'TContact.$HasEmail'() { return !!this.Email; },
        },
        validators: {
            'Contact.Name': '@[Error.Required]',
            'Contact.Email': { valid: "email", msg: '@[Error.Email]' }
        },
        defaults: {}
    };
    exports.default = template;
});
