define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TCountry.$Id'() { return this.Id || '@[NewItem]'; },
        },
        defaults: {},
        validators: {
            'Country.Id': ['@[Error.Required]', { valid: validLen3, msg: '@[Error.Country.Len3]' }],
            'Country.Alpha2': ['@[Error.Required]', { valid: validLen2, msg: '@[Error.Country.Len2]' }],
            'Country.Alpha3': ['@[Error.Required]', { valid: validLen3, msg: '@[Error.Country.Len3]' }],
            'Country.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
    function validLen2(elem, val) {
        return val.length === 2;
    }
    function validLen3(elem, val) {
        return val.length === 3;
    }
    function checkDup(elem, val) {
        if (!val)
            return true;
        if (!validLen3(elem, val))
            return true;
        return elem.$ctrl.$asyncValid('checkDuplicate', { Id: elem.Id });
    }
});
