define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRepDataArray.$CrossNames': crossNames
        },
        commands: {
            clearFilter
        }
    };
    exports.default = template;
    function crossNames() {
        let wharr = this.$root.Warehouses;
        let arr = this.$cross.WhCross;
        return arr.map(x => { var _a; return (_a = wharr.find(w => w.Key === x)) === null || _a === void 0 ? void 0 : _a.Name; });
    }
    function clearFilter(filter) {
        filter.Company.Id = -1;
        filter.Company.Name = '';
    }
});
