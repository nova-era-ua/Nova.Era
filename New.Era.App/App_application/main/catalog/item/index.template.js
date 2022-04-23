define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$SelectedElem': hasSelectedElem,
        },
        events: {},
        commands: {}
    };
    exports.default = template;
    function hasSelectedElem() {
        var _a;
        let sel = this.Groups.$selected;
        if (!sel)
            return undefined;
        return (_a = sel.Elements.$selected) === null || _a === void 0 ? void 0 : _a.Id;
    }
});
