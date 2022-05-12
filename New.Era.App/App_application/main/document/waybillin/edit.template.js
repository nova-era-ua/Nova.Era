define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {},
        defaults: {
            'Document.WhTo'() { return this.Default.Warehouse; },
            'Document.Extra.WriteSupplierPrices': true
        },
        validators: {
            'Document.WhTo': '@[Error.Required]'
        },
        events: {
            'Document.ServiceRows[].Item.change': itemChange,
            'Document.ServiceRows[].ItemRole.change': itemRoleChange
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
        let svcSum = this.Document.$ServiceSum;
        let stockSum = this.Document.$StockSum;
        if (!svcSum || !stockSum)
            return;
        let k = svcSum / stockSum;
        this.Document.StockRows.forEach(row => row.ESum = utils.currency.round(row.Sum * k, 2));
    }
});
