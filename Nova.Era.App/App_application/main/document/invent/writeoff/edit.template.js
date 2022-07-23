define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$ExpenseItemRoles'() { return this.ItemRoles.filter(r => r.Kind === 'Expense'); },
            'TRoot.$CheckRems'() { return !this.Document.Done && this.Params.CheckRems; },
            'TRoot.$BrowseStockArg'() { return { IsStock: 'T', Date: this.Document.Date, CheckRems: this.$CheckRems, Wh: this.Document.WhFrom.Id }; },
        },
        defaults: {
            'Document.WhFrom'() { return this.Default.Warehouse; },
        },
        validators: {
            'Document.Agent': null,
            'Document.WhFrom': '@[Error.Required]',
            'Document.ItemRole': '@[Error.Required]',
            'Document.StockRows[].Qty': [
                '@[Error.Required]',
                { valid: checkRems, applyIf: checkRemsApply, msg: '@[Error.InsufficientAmount]' }
            ],
            'Document.StockRows[].CostItem': '@[Error.Required]'
        },
        events: {
            'Document.Date.change': dateChange,
            'Document.StockRows[].Item.change': itemChange,
            'Document.WhFrom.change': whFromChange,
            'Document.StockRows[].ItemRole.change': itemRoleChange,
            'Document.ItemRole.change': docItemRoleChange
        },
        commands: {
            reloadRems
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function checkRems(elem, val) {
        return elem.Qty <= elem.Rem;
    }
    function checkRemsApply(elem, val) {
        return elem.$root.$CheckRems;
    }
    function itemChange(row, val) {
        base.events['Document.StockRows[].Item.change'].call(this, row, val);
        row.Price = val.Price;
        row.ItemRoleTo = val.Role;
        if (utils.isDefined(val.Rem)) {
            row.Rem = val.Rem;
        }
    }
    async function dateChange(doc) {
        if (!this.$CheckRems)
            return;
        if (doc.StockRows.$isEmpty)
            return;
        const ctrl = this.$ctrl;
        remChange.call(this, doc);
    }
    async function whFromChange(doc) {
        if (!this.$CheckRems)
            return;
        if (doc.StockRows.$isEmpty)
            return;
        const ctrl = this.$ctrl;
        remChange.call(this, doc);
    }
    async function itemRoleChange(row, role) {
        var _a;
        row.CostItem = role.CostItem;
        if (!this.$CheckRems)
            return;
        const ctrl = this.$ctrl;
        let doc = this.Document;
        let result = await ctrl.$invoke('getItemRoleRem', { Item: row.Item.Id, Role: role.Id, Date: doc.Date, Wh: doc.WhFrom.Id });
        row.Rem = ((_a = result === null || result === void 0 ? void 0 : result.Result) === null || _a === void 0 ? void 0 : _a.Rem) || 0;
    }
    async function docItemRoleChange(doc, role) {
        doc.StockRows.forEach(row => {
            row.CostItem = role.CostItem;
        });
    }
    function reloadRems() {
        remChange.call(this, this.Document);
    }
    async function remChange(doc) {
        const ctrl = this.$ctrl;
        let stocks = doc.StockRows.map(r => r.Item.Id);
        let services = doc.ServiceRows.map(r => r.Item.Id);
        let items = stocks.concat(services).join(',');
        let result = await ctrl.$invoke('getRems', { Items: items, Date: doc.Date, Wh: doc.WhFrom.Id });
        doc.StockRows.forEach(row => {
            let rem = result.Rems.find(p => p.Item === row.Item.Id && p.Role == row.ItemRole.Id);
            row.Rem = (rem === null || rem === void 0 ? void 0 : rem.Rem) || 0;
        });
    }
});
