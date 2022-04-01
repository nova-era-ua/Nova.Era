define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TWarehouse.$Id'() { return this.Id || '@[NewItem]'; }
        },
        validators: {
            'Warehouse.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
