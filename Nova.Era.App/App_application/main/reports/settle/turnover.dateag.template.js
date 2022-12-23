define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const utils = require("std:utils");
    const du = utils.date;
    const base = require("reports/_common/simple.module");
    const template = {
        properties: {
            'TRepData.$Name'() { return this.$level === 1 ? du.formatDate(this.Date) : this.Agent.Name; },
        }
    };
    exports.default = utils.mergeTemplate(base, template);
});
