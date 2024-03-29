define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const mod = require('/catalog/crm/leadstage/_stage.module');
    const template = {
        properties: {
            'TStage.$Kind'() { return mod.kind2Text(this.Kind); }
        },
    };
    exports.default = template;
});
