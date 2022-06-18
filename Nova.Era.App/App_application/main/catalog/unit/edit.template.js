define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TUnit.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Unit.Short': '@[Error.Required]',
            'Unit.Name': '@[Error.Required]',
            'Unit.CodeUA': { valid: validCode, msg: '@[Error.UnitCodeUA]' }
        }
    };
    exports.default = template;
    function validCode(unit) {
        return !unit.CodeUA || unit.CodeUA.length === 4;
    }
});
