define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {},
        validators: {
            'Tags[].Name': '@[Error.Required]'
        },
        events: {
            'Tags[].add': tagAdd
        },
        commands: {}
    };
    exports.default = template;
    function tagAdd(tags, tag) {
        tag.For = this.Params.For;
    }
});
