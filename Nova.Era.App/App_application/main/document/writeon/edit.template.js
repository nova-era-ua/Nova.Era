define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require('/document/_common/stock.module');
    const utils = require("std:utils");
    const template = {
        properties: {
            'TRoot.$RevenueItemRoles'() { return this.ItemRoles.filter(r => r.Kind === 'Revenue'); },
            'TRoot.$CheckRems'() { return !this.Document.Done && this.Params.CheckRems; },
            'TRoot.$BrowseStockArg'() { return { IsStock: 'T', Date: this.Document.Date, CheckRems: this.$CheckRems, Wh: this.Document.WhFrom.Id }; },
        },
        defaults: {
            'Document.WhFrom'() { return this.Default.Warehouse; },
        },
        validators: {
            'Document.Agent': null,
            'Document.WhTo': '@[Error.Required]',
            'Document.ItemRole': '@[Error.Required]',
            'Document.StockRows[].Qty': '@[Error.Required]'
        },
        events: {
            'Document.StockRows[].ItemRole.change': itemRoleChange,
            'Document.ItemRole.change': docItemRoleChange
        },
        commands: {}
    };
    exports.default = utils.mergeTemplate(base, template);
    function checkRems(elem, val) {
        return elem.Qty <= elem.Rem;
    }
    function checkRemsApply(elem, val) {
        return elem.$root.$CheckRems;
    }
    async function itemRoleChange(row, role) {
        row.CostItem = role.CostItem;
    }
    async function docItemRoleChange(doc, role) {
        doc.StockRows.forEach(row => {
            row.CostItem = role.CostItem;
        });
    }
});
