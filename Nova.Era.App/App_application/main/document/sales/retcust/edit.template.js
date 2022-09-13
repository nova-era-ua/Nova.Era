define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$ItemRolesStock'() { return this.ItemRoles.filter(r => r.Kind === 'Item' && r.IsStock); },
            'TRoot.$IsStockArg'() { return { IsStock: 'T' }; },
        },
        defaults: {
            'Document.WhFrom'() { return this.Default.Warehouse; },
        },
        validators: {
            'Document.WhTo': '@[Error.Required]'
        },
    };
    exports.default = utils.mergeTemplate(base, template);
});
