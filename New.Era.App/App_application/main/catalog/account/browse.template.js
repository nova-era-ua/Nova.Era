define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const tu = require('std:utils').text;
    const template = {
        properties: {
            'TRoot.$Search': String,
            'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
            'TAccount.$Icon'() { return this.IsFolder ? 'account-folder' : 'account'; }
        },
        events: {
            'Root.$Search.change': searchAccount,
        }
    };
    exports.default = template;
    function searchAccount(root, text) {
        if (!text)
            return;
        let found = root.Accounts.$find(el => el.Code.indexOf(text) === 0 || tu.contains(el.Name, text));
        if (found)
            found.$select(root.Accounts);
        else
            root.$Search = '';
    }
});
