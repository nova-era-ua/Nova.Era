define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {},
        commands: {
            testInvoke
        }
    };
    exports.default = template;
    async function testInvoke() {
        let ctrl = this.$ctrl;
        await ctrl.$invoke('getPrices', { Items: '100,200,201', PriceKind: 5, Date: '20220101' }, '/document/sales/invoice', { hideIndicator: true });
    }
});
