define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("document/_common/index.module");
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$CashAccLabel': cashAccText,
            'TCashAccount.$Name'() { return this.Name || this.AccountNo; },
            'TDocument.$SumDir': sumDir,
            'TDocument.$CashAccount': cashAccountText
        },
        commands: {
            browseCashAccount
        },
        delegates: {
            browseCashDelegate
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function cashAccText() {
        return this.Params.AccMode === 'Cash' ? '@[CashAccount]' :
            this.Params.AccMode === 'Bank' ? '@[BankAccount]' :
                '@[Label.Cash.Account]';
    }
    function cashAccountText() {
        var _a, _b, _c, _d, _e;
        if (((_a = this.CashAccFrom) === null || _a === void 0 ? void 0 : _a.Id) && ((_b = this.CashAccTo) === null || _b === void 0 ? void 0 : _b.Id))
            return `${this.CashAccFrom.$Name} -> ${this.CashAccTo.$Name}`;
        return ((_c = this.CashAccFrom) === null || _c === void 0 ? void 0 : _c.Id) ? (_d = this.CashAccFrom) === null || _d === void 0 ? void 0 : _d.$Name : (_e = this.CashAccTo) === null || _e === void 0 ? void 0 : _e.$Name;
    }
    function sumDir() {
        var _a, _b, _c;
        if (((_a = this.CashAccFrom) === null || _a === void 0 ? void 0 : _a.Id) && ((_b = this.CashAccTo) === null || _b === void 0 ? void 0 : _b.Id))
            return 0;
        return ((_c = this.CashAccFrom) === null || _c === void 0 ? void 0 : _c.Id) ? -1 : 1;
    }
    async function browseCashAccount(filter) {
        const ctrl = this.$ctrl;
        let url = '/catalog/cashaccount/browseall';
        let dat = {
            Company: filter.Company.Id,
            Mode: this.Params.AccMode
        };
        let res = await ctrl.$showDialog(url, filter.CashAccount, dat);
        filter.CashAccount.Id = res.Id;
        filter.CashAccount.Name = res.Name;
    }
    function browseCashDelegate(item, text) {
        var _a, _b;
        const ctrl = this.$ctrl;
        let url = '/catalog/cashaccount';
        let filter = (_b = (_a = this.Documents) === null || _a === void 0 ? void 0 : _a.$ModelInfo) === null || _b === void 0 ? void 0 : _b.Filter;
        let dat = {
            Company: filter.Company.Id,
            Mode: this.Params.AccMode,
            Text: text
        };
        return ctrl.$invoke('fetchall', dat, url);
    }
});
