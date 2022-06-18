define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$CheckRems'() { return !this.Document.Done && this.Params.CheckRems; },
            'TRoot.$StockSpan'() { return this.$CheckRems ? 5 : 4; },
            'TRoot.$BrowseStockArg'() { return { IsStock: 'T', PriceKind: this.Document.PriceKind.Id, Date: this.Document.Date, CheckRems: this.$CheckRems, Wh: this.Document.WhFrom.Id }; },
            'TRoot.$BrowseServiceArg'() { return { IsStock: 'V', PriceKind: this.Document.PriceKind.Id, Date: this.Document.Date }; }
        },
        defaults: {
            'Document.WhFrom'() { return this.Default.Warehouse; }
        },
        validators: {
            'Document.WhFrom': '@[Error.Required]',
            'Document.StockRows[].Price': '@[Error.Required]',
            'Document.ServiceRows[].Price': '@[Error.Required]',
            'Document.StockRows[].Qty': [
                '@[Error.Required]',
                { valid: checkRems, applyIf: checkRemsApply, msg: '@[Error.InsufficientAmount]' }
            ]
        },
        events: {
            'Document.Date.change': dateChange,
            'Document.Contract.change': contractChange,
            'Document.StockRows[].Item.change': itemChange,
            'Document.ServiceRows[].Item.change': itemChange,
            'Document.PriceKind.change': priceKindChange,
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
    function contractChange(doc, contract) {
        doc.PriceKind.$set(contract.PriceKind);
    }
    function itemChange(row, val) {
        base.events['Document.StockRows[].Item.change'].call(this, row, val);
        row.Price = val.Price;
        if (utils.isDefined(val.Rem)) {
            row.Rem = val.Rem;
        }
    }
    async function dateChange(doc) {
        if (!doc.PriceKind.Id)
            return;
        if (doc.StockRows.$isEmpty && doc.ServiceRows.$isEmpty)
            return;
        const ctrl = this.$ctrl;
        if (!await ctrl.$confirm('Дата документу змінилася.\nОновити ціни та залишки в документі?'))
            return;
        priceOrRemChange.call(this, doc);
    }
    async function priceKindChange(doc) {
        if (!doc.PriceKind.Id)
            return;
        if (doc.StockRows.$isEmpty && doc.ServiceRows.$isEmpty)
            return;
        const ctrl = this.$ctrl;
        if (!await ctrl.$confirm('Тип ціни змінився. Оновити ціни в документі?'))
            return;
        priceOrRemChange.call(this, doc);
    }
    async function whFromChange(doc) {
        if (!this.$CheckRems)
            return;
        if (doc.StockRows.$isEmpty && doc.ServiceRows.$isEmpty)
            return;
        const ctrl = this.$ctrl;
        if (!await ctrl.$confirm('Склад змінився. Оновити залишки в документі?'))
            return;
        priceOrRemChange.call(this, doc);
    }
    function reloadRems() {
        priceOrRemChange.call(this, this.Document);
    }
    async function priceOrRemChange(doc) {
        const ctrl = this.$ctrl;
        let stocks = doc.StockRows.map(r => r.Item.Id);
        let services = doc.ServiceRows.map(r => r.Item.Id);
        let items = stocks.concat(services).join(',');
        let result = await ctrl.$invoke('getPricesAndRems', { Items: items, PriceKind: doc.PriceKind.Id, Date: doc.Date, Wh: doc.WhFrom.Id });
        doc.StockRows.concat(doc.ServiceRows).forEach(row => {
            let price = result.Prices.find(p => p.Item === row.Item.Id);
            row.Price = (price === null || price === void 0 ? void 0 : price.Price) || 0;
        });
        doc.StockRows.forEach(row => {
            let rem = result.Rems.find(p => p.Item === row.Item.Id);
            row.Rem = (rem === null || rem === void 0 ? void 0 : rem.Rem) || 0;
        });
    }
});
