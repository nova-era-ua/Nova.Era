define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRespCenter.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'RespCenter.Name': '@[Error.Required]',
        }
    };
    exports.default = template;
});
