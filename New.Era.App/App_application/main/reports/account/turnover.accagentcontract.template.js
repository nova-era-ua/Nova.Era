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
            'TRepDataArray.$CtColSpan'() { return this.$cross.CtCross.length + 1; }
        },
        events: {
            'Model.load': modelLoad
        }
    };
    exports.default = template;
    function calcCrossTotals(elem) {
        elem.Items.forEach(itemOut => {
            calcCrossTotals(itemOut);
            itemOut.Items.forEach(itemIn => {
                itemOut.CtCross.forEach((e, i) => e.Sum += itemIn.CtCross[i].Sum);
                itemOut.DtCross.forEach((e, i) => e.Sum += itemIn.DtCross[i].Sum);
            });
        });
    }
    function modelLoad() {
        calcCrossTotals(this.RepData);
        this.RepData.Items.forEach(item => {
            this.RepData.CtCross.forEach((e, i) => e.Sum += item.CtCross[i].Sum);
            this.RepData.DtCross.forEach((e, i) => e.Sum += item.DtCross[i].Sum);
        });
    }
});
