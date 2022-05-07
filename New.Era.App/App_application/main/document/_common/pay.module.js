define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/common.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TDocument.$CompanyArg'() { var _a; return { Company: (_a = this.Company) === null || _a === void 0 ? void 0 : _a.Id }; },
        }
    };
    exports.default = utils.mergeTemplate(base, template);
});
