define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$Disabled1': getDisabled(1),
            'TRoot.$Disabled2': getDisabled(2),
            'TRoot.$Disabled3': getDisabled(3),
            'TPriceItem.$Price1': getPriceProp(1),
            'TPriceItem.$Price2': getPriceProp(2),
            'TPriceItem.$Price3': getPriceProp(3)
        },
        commands: {},
        events: {}
    };
    exports.default = template;
    function getDisabled(no) {
        return function () {
            let pk = this.Checked[`PriceKind${no}`];
            return pk.Id ? false : true;
        };
    }
    function getPriceProp(no) {
        return {
            get() {
                let pk = this.$root.Checked[`PriceKind${no}`];
                if (!pk || !pk.Id)
                    return 0;
                let val = this.Values.find(v => v.PriceKind == pk.Id);
                return val ? val.Price : 0;
            },
            async set(val) {
                var _a, _b;
                let pk = this.$root.Checked[`PriceKind${no}`];
                if (!pk)
                    return;
                let date = (_b = (_a = this.$parent.$ModelInfo) === null || _a === void 0 ? void 0 : _a.Filter) === null || _b === void 0 ? void 0 : _b.Date;
                if (!date)
                    return;
                let pval = this.Values.find(v => v.PriceKind == pk.Id);
                if (pval)
                    pval.Price = val;
                else
                    this.Values.$append({ PriceKind: pk.Id, Date: date, Price: val });
                await this.$ctrl.$invoke('setPrice', { Id: this.Id, PriceKind: pk.Id, Date: date, Value: val });
            }
        };
    }
});
