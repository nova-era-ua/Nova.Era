define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$CreateData'() { var _a; return { Parent: (_a = this.Groups.$selected) === null || _a === void 0 ? void 0 : _a.Id }; }
        },
        validators: {}
    };
    exports.default = template;
});
