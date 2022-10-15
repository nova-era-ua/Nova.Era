define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const mod = require('/catalog/crm/leadstage/_stage.module');
    const template = {
        properties: {
            'TStage.$Id'() { return this.Id || '@[NewItem]'; },
            'TStage.$Kind'() { return mod.kind2Text(this.Kind); },
            'TStage.$IsOnce'() { return this.Kind === 'S' || this.Kind === 'I'; }
        },
        validators: {
            'Stage.Name': '@[Error.Required]',
        },
        defaults: {
            "Stage.Order"() { return this.Params.NextOrdinal; },
            "Stage.Kind": 'P'
        }
    };
    exports.default = template;
});
