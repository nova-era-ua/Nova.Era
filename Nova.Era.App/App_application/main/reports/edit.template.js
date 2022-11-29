define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        defaults: {
            'Report.Menu'() { return this.Params.Menu; },
            'Report.Type'() { return this.RepTypes[0]; }
        },
        properties: {
            'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
        },
        validators: {
            'Report.Name': '@[Error.Required]',
            'Report.Account': { valid: validAccount, msg: '@[Error.Required]' },
            'Report.File': '@[Error.Required]'
        }
    };
    exports.default = template;
    function validAccount(elem, val) {
        console.dir(val);
        switch (elem.Type.Id) {
            case 'by.account': return !!elem.Account.Id;
        }
        return true;
    }
});
