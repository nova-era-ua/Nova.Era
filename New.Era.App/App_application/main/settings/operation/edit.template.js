define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$Tab': String,
            'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]'; }
        },
        defaults: {
            "Operation.Group"() { return this.Params.ParentGroup; }
        },
        validators: {
            'Operation.Form': '@[Error.Required]',
            'Operation.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
