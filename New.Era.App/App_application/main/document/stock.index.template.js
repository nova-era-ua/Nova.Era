define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("document/_common/index.module");
    const tmlUtils = require('std:tmlutils');
    const template = {
        properties: {
            'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name; }
        }
    };
    exports.default = tmlUtils.mergeTemplate(base, template);
});
