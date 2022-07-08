define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$ItemRolesSvc'() { return this.ItemRoles.filter(r => r.Kind === 'Item' && !r.IsStock); },
            'TRoot.$ItemRolesStock'() { return this.ItemRoles.filter(r => r.Kind === 'Item' && r.IsStock); },
            'TRoot.$IsStockArg'() { return { IsStock: 'T' }; },
            'TRoot.$IsNoStockArg'() { return { IsStock: 'V' }; }
        },
        defaults: {
            'Document.WhTo'() { return this.Default.Warehouse; },
            'Document.Extra.WriteSupplierPrices': true
        },
        validators: {
            'Document.WhTo': '@[Error.Required]',
            'Document.$StockESum': validStockESum
        },
        events: {
            'Document.ServiceRows[].Item.change': itemChange,
            'Document.ServiceRows[].ItemRole.change': itemRoleChange,
            'Document.Extra.IncludeServiceInCost.change': flagIncludeChange
        },
        commands: {
            distributeBySum
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function itemChange(row, val) {
        base.events['Document.ServiceRows[].Item.change'].call(this, row, val);
        row.CostItem = val.Role.CostItem;
    }
    function itemRoleChange(row, val) {
        row.CostItem = val.CostItem;
    }
    function distributeBySum() {
        if (!this.Document.Extra.IncludeServiceInCost)
            return;
        let stockRows = this.Document.StockRows;
        let svcSum = this.Document.$ServiceSum;
        let stockSum = this.Document.$StockSum;
        if (!svcSum || !stockSum)
            return;
        let k = svcSum / stockSum;
        stockRows.forEach(row => row.ESum = utils.currency.round(row.Sum * k, 2));
        let total = stockRows.reduce((p, c) => p + c.ESum, 0);
        if (total != svcSum) {
            let count = stockRows.length;
            if (count < 2)
                return;
            let sumM1 = stockRows.reduce((p, c, ix) => p + (ix === count - 1 ? 0 : c.ESum), 0);
            stockRows[count - 1].ESum = svcSum - sumM1;
        }
    }
    function validStockESum(doc) {
        if (!doc.Extra.IncludeServiceInCost)
            return true;
        if (doc.$StockESum !== doc.$ServiceSum)
            return 'Сума націнки не співпадає з сумою послуг';
        return true;
    }
    function flagIncludeChange(extra, val) {
        if (!val)
            this.Document.StockRows.forEach(row => row.ESum = 0);
    }
});
