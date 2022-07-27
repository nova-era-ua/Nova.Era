define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/common.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TDocument.$CompanyArg'() { var _a; return { Company: (_a = this.Company) === null || _a === void 0 ? void 0 : _a.Id }; },
            'TCashAccount.$Balance'() { return `@[Rem]: ${utils.currency.format(this.Balance)}`; },
            'TCashAccount.$InfoUrl'() { return `/catalog/cashaccount/info/${this.Id}`; }
        },
        events: {
            'Document.Date.change': dateChange
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    async function dateChange(doc, date) {
        if (!doc.CashAccFrom.Id)
            return;
        const ctrl = this.$ctrl;
        let res = await ctrl.$invoke('getrem', { Id: doc.CashAccFrom.Id, Date: doc.Date }, '/catalog/cashaccount');
        doc.CashAccFrom.Balance = res.Result.Balance;
    }
});
