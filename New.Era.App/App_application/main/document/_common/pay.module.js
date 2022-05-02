define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TRoot.$CompArg'() { var _a; return { Company: (_a = this.Document.Company) === null || _a === void 0 ? void 0 : _a.Id }; }
        },
        defaults: {
            'Document.Date': dateUtils.today(),
            'Document.Operation'() { return this.Operations.find(o => o.Id === this.Params.Operation); },
            'Document.Company'() { return this.Default.Company; },
            'Document.RespCenter'() { return this.Default.RespCenter; }
        },
        validators: {
            'Document.Company': '@[Error.Required]',
            'Document.Agent': '@[Error.Required]',
        },
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
