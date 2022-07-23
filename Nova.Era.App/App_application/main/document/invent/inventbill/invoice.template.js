define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$$Scan': String,
            'TRoot.$BrowseStockArg'() { return { IsStock: 'T', PriceKind: this.Document.PriceKind.Id, Date: this.Document.Date }; },
            'TRoot.$BrowseServiceArg'() { return { IsStock: 'V', PriceKind: this.Document.PriceKind.Id, Date: this.Document.Date }; }
        },
        events: {
            'Document.Date.change': dateChange,
            'Document.Contract.change': contractChange,
            'Document.PriceKind.change': priceKindChange,
            'Document.StockRows[].Item.change': itemChange,
            'Document.ServiceRows[].Item.change': itemChange,
        },
        validators: {
            'Document.StockRows[].Price': '@[Error.Required]',
            'Document.ServiceRows[].Price': '@[Error.Required]'
        },
        commands: {}
    };
    exports.default = utils.mergeTemplate(base, template);
    function contractChange(doc, contract) {
        base.events['Document.Contract.change'].call(this, doc, contract);
        doc.PriceKind.$set(contract.PriceKind);
    }
    async function dateChange(doc) {
        if (!doc.PriceKind.Id)
            return;
        if (doc.StockRows.$isEmpty && doc.ServiceRows.$isEmpty)
            return;
        const ctrl = this.$ctrl;
        if (!await ctrl.$confirm('Дата документу змінилася. Оновити ціни в документі?'))
            return;
        priceChange.call(this, doc);
    }
    async function priceKindChange(doc) {
        if (!doc.PriceKind.Id)
            return;
        if (doc.StockRows.$isEmpty && doc.ServiceRows.$isEmpty)
            return;
        const ctrl = this.$ctrl;
        if (!await ctrl.$confirm('Тип ціни змінився. Оновити ціни в документі?'))
            return;
        priceChange.call(this, doc);
    }
    async function priceChange(doc) {
        const ctrl = this.$ctrl;
        let stocks = doc.StockRows.map(r => r.Item.Id);
        let services = doc.ServiceRows.map(r => r.Item.Id);
        let items = stocks.concat(services).join(',');
        let result = await ctrl.$invoke('getPrices', { Items: items, PriceKind: doc.PriceKind.Id, Date: doc.Date });
        doc.StockRows.concat(doc.ServiceRows).forEach(row => {
            let price = result.Prices.find(p => p.Item === row.Item.Id);
            row.Price = (price === null || price === void 0 ? void 0 : price.Price) || 0;
        });
    }
    function itemChange(row, val) {
        base.events['Document.StockRows[].Item.change'].call(this, row, val);
        row.Price = val.Price;
    }
});
