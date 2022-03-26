define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        defaults: {
            'Document.Operation'() { return this.Operations[0]; }
        },
        properties: {},
        commands: {}
    };
    exports.default = template;
});
