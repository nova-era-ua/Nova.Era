define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("reports/_common/simple.module");
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRepDataArray.$CrossNames': crossNames
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function crossNames() {
        let wharr = this.$root.Warehouses;
        let arr = this.$cross.WhCross;
        return arr.map(x => { var _a; return (_a = wharr.find(w => w.Key === x)) === null || _a === void 0 ? void 0 : _a.Name; });
    }
});
