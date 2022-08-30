define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("reports/_common/simple.module");
    const utils = require("std:utils");
    const template = {
        properties: {
            'TAccount.$Name'() { return `${this.Code} ${this.Name}`; },
            'TRepData.$DtStart': total('DtStart'),
            'TRepData.$CtStart': total('CtStart'),
            'TRepData.$DtEnd': total('DtEnd'),
            'TRepData.$CtEnd': total('CtEnd')
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function total(prop) {
        return function () {
            return this.Items.reduce((p, c) => p + c[prop], 0);
        };
    }
});
