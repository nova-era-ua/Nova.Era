define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TProject.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Project.Name': '@[Error.Required]',
        }
    };
    exports.default = template;
});
