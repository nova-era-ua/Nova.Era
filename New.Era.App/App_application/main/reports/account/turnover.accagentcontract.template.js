define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const du = require('std:utils').date;
    const template = {
        properties: {
            'TAccount.$Name'() { return `${this.Code} ${this.Name}`; },
            'TContract.$Name'() { var _a; return !this.Id ? '' : ((_a = this.Name) !== null && _a !== void 0 ? _a : `№ ${this.SNo} від ${du.formatDate(this.Date)}`); },
            'TRepData.$Name'() { return this.$level === 1 ? this.Agent.Name : (this.Contract.$Name || '@[NoContract]'); },
            'TRepDataArray.$DtColSpan'() { return this.$cross.DtCross.length + 1; },
            'TRepDataArray.$CtColSpan'() { return this.$cross.CtCross.length + 1; },
            'TRepDataArray.$DtTotals': dtTotals,
            'TRepDataArray.$CtTotals': ctTotals
        }
    };
    exports.default = template;
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
