define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const mod = require('/catalog/docstate/_state.module');
    const template = {
        properties: {
            'TForm.$CreateArg'() { return { Form: this.Id }; },
            'TState.$Kind'() { return mod.kind2Text(this.Kind); }
        },
        defaults: {},
        validators: {}
    };
    exports.default = template;
});
