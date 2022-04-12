define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        defaults: {
            'Report.Menu'() { return this.Params.Menu; }
        },
        properties: {
            'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
            'TReport.$RepTypes': repTypes
        },
        validators: {
            'Report.Name': '@[Error.Required]',
            'Report.Account': '@[Error.Required]',
            'Report.Url': '@[Error.Required]'
        }
    };
    exports.default = template;
    function repTypes() {
        let r = [];
        let acc = this.Account;
        if (acc.IsItem)
            r.push({ Name: 'Оборотная ведомость "Товар"', Url: '/reports/stock/rto_items' });
        if (acc.IsWarehouse)
            r.push({ Name: 'Оборотная ведомость "Склад+товар"', Url: '/reports/stock/rto_whitems' });
        if (acc.IsAgent)
            r.push({ Name: 'Оборотная ведомость "Контрагент"', Url: '/reports/agent/rto_agents' });
        return r;
    }
});
