define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TCurrency.$Id'() { return this.Id || '@[NewItem]'; },
            'TCurrency.NewId'() { return +this.Number3; }
        },
        defaults: {
            'Currency.Denom': 1
        },
        validators: {
            'Currency.Number3': [
                '@[Error.Required]',
                { valid: validLen, msg: '@[Error.Currency.Len]' },
                { async: true, valid: checkDup, msg: '@[Error.Currency.DuplicateCode]' }
            ],
            'Currency.Alpha3': ['@[Error.Required]', { valid: validLen, msg: '@[Error.Currency.Len]' }]
        }
    };
    exports.default = template;
    function validLen(elem, val) {
        return val.length === 3;
    }
    function checkDup(elem, val) {
        if (!val)
            return true;
        if (!validLen(elem, val))
            return true;
        return elem.$ctrl.$asyncValid('checkDuplicate', { Id: elem.Id, Number3: val });
    }
});
