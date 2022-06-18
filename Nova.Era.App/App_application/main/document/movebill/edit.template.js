define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$CheckRems'() { return !this.Document.Done && this.Params.CheckRems; },
            'TRoot.$ItemRolesStock'() { return this.ItemRoles.filter(r => r.IsStock); },
            'TRoot.$BrowseStockArg'() { return { IsStock: 'T', Date: this.Document.Date, CheckRems: this.$CheckRems, Wh: this.Document.WhFrom.Id }; },
        },
        defaults: {
            'Document.WhFrom'() { return this.Default.Warehouse; },
        },
        validators: {
            'Document.Agent': null,
            'Document.WhTo': '@[Error.Required]',
            'Document.WhFrom': '@[Error.Required]',
            'Document.StockRows[].Qty': [
                '@[Error.Required]',
                { valid: checkRems, applyIf: checkRemsApply, msg: '@[Error.InsufficientAmount]' }
            ]
        },
        events: {
            'Document.Date.change': dateChange,
            'Document.StockRows[].Item.change': itemChange,
            'Document.WhFrom.change': whFromChange
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
        if (!await ctrl.$confirm('Дата документу змінилася.\nОновити залишки в документі?'))
            return;
        remChange.call(this, doc);
    }
    async function whFromChange(doc) {
        if (!this.$CheckRems)
            return;
        if (doc.StockRows.$isEmpty)
            return;
        const ctrl = this.$ctrl;
        if (!await ctrl.$confirm('Склад змінився. Оновити залишки в документі?'))
            return;
        remChange.call(this, doc);
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
            let rem = result.Rems.find(p => p.Item === row.Item.Id);
            row.Rem = (rem === null || rem === void 0 ? void 0 : rem.Rem) || 0;
        });
    }
});
