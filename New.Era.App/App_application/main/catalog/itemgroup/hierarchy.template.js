define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TGroup.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Group.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
