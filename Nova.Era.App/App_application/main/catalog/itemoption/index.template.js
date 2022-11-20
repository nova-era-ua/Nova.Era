define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TOption.$Items'() { return this.Items.map(x => x.Name).join(', '); }
        },
        events: {},
        commands: {}
    };
    exports.default = template;
});
