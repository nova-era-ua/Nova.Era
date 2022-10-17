define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const mod = require('/catalog/docstate/_state.module');
    const template = {
        properties: {
            'TState.$Id'() { return this.Id || '@[NewItem]'; },
            'TState.$Kind'() { return mod.kind2Text(this.Kind); },
            'TState.$IsOnce'() { return this.Kind === 'S' || this.Kind === 'I'; }
        },
        validators: {
            'State.Name': '@[Error.Required]',
        },
        defaults: {
            "State.Kind": 'P',
            "State.Order"() { return this.Params.NextOrdinal; },
            'State.Form'() { return this.Params.Form; }
        }
    };
    exports.default = template;
});
