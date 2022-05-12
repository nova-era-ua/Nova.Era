define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$CreateArg': createArg
        },
        commands: {
            clearFilter
        }
    };
    exports.default = template;
    function clearFilter(elem) {
        elem.Id = 0;
        elem.Name = '';
    }
    function createArg() {
        var _a, _b;
        let filter = (_b = (_a = this.Contracts) === null || _a === void 0 ? void 0 : _a.$ModelInfo) === null || _b === void 0 ? void 0 : _b.Filter;
        let r = {};
        if (filter.Agent.Id)
            r.Agent = filter.Agent.Id;
        if (filter.Company.Id)
            r.Company = filter.Company.Id;
        return r;
    }
});
