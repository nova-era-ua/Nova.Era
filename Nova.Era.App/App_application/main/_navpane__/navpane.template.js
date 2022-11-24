define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const eventBus = require('std:eventBus');
    const template = {
        properties: {
            'TRoot.$Text'() { return "Text"; },
            'TRoot.$Badge'() { return '9'; }
        },
        commands: {
            showPane
        },
        events: {
            "Model.load": modelLoad
        }
    };
    exports.default = template;
    function showPane() {
        let ctrl = this.$ctrl;
        ctrl.$showSidePane('notification', 22, { X: 5, Y: 7 });
    }
    function modelLoad() {
        let ctrl = this.$ctrl;
        console.dir('start timeout');
        setInterval(async () => {
            let res = await ctrl.$invoke('getPrices', { Items: '100,200,201', PriceKind: 5, Date: '20220101' }, '/document/sales/invoice', { hideIndicator: true });
            console.dir(res);
        }, 3000);
    }
});
