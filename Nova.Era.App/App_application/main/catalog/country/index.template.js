define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        commands: {
            addFromSite
        }
    };
    exports.default = template;
    async function addFromSite() {
        const ctrl = this.$ctrl;
        let result = await ctrl.$showDialog('/catalog/country/download');
        ctrl.$reload();
    }
});
