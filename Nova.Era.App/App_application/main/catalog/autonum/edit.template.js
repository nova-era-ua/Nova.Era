define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TAutonum.$Id'() { return this.Id || '@[NewItem]'; },
        },
        defaults: {
            'Autonum.Period': 'Y'
        },
        validators: {
            'Autonum.Name': '@[Error.Required]',
            'Autonum.Pattern': '@[Error.Required]'
        }
    };
    exports.default = template;
});
