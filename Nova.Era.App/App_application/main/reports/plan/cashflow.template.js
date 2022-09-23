define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("reports/_common/simple.module");
    const utils = require("std:utils");
    const template = {
        properties: {}
    };
    exports.default = utils.mergeTemplate(base, template);
});
