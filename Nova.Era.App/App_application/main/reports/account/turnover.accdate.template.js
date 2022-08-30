define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const utils = require("std:utils");
    const base = require("reports/_common/simple.module");
    const template = {
        properties: {
            'TAccount.$Name'() { return `${this.Code} ${this.Name}`; },
            'TRepDataArray.$DtColSpan'() { return this.$cross.DtCross.length + 1; },
            'TRepDataArray.$CtColSpan'() { return this.$cross.CtCross.length + 1; },
            'TRepDataArray.$DtTotals': dtTotals,
            'TRepDataArray.$CtTotals': ctTotals
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function dtTotals() {
        return this.$cross.DtCross.map(x => {
            return {
                Sum: this.reduce((prev, curr) => prev + curr.DtCross.find(ci => ci.Acc === x).Sum, 0)
            };
        });
    }
    function ctTotals() {
        return this.$cross.CtCross.map(x => {
            return {
                Sum: this.reduce((prev, curr) => prev + curr.CtCross.find(ci => ci.Acc === x).Sum, 0)
            };
        });
    }
});
