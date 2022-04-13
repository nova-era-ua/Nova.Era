define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TRoot.$CompArg'() { var _a; return { Company: (_a = this.Document.Company) === null || _a === void 0 ? void 0 : _a.Id }; },
            'TBankAccount.$Name'() { return this.Name || this.AccountNo; }
        },
        defaults: {
            'Document.Date': dateUtils.today(),
            'Document.Operation'() { return this.Operations[0]; },
            'Document.Company'() { return this.Default.Company; }
        },
        validators: {
            'Document.Company': '@[Error.Required]',
            'Document.Agent': '@[Error.Required]',
            'Document.BankAccTo': '@[Error.Required]'
        },
        events: {},
        commands: {
            apply,
            unApply
        }
    };
    exports.default = template;
    async function apply() {
        const ctrl = this.$ctrl;
        let result = await ctrl.$invoke('apply', { Id: this.Document.Id });
        ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: true });
        ctrl.$requery();
    }
    async function unApply() {
        let ctrl = this.$ctrl;
        let result = await ctrl.$invoke('unApply', { Id: this.Document.Id });
        ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: false });
        ctrl.$requery();
    }
});
