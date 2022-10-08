define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TStage.$Id'() { return this.Id || '@[NewItem]'; },
        },
        validators: {
            'Stage.Name': '@[Error.Required]',
        },
        defaults: {
            "Stage.Order"() { return this.Params.NextOrdinal; }
        }
    };
    exports.default = template;
});
