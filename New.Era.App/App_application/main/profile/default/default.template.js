define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        events: {
            'Default.Company.change': companyChange,
            'Default.Warehouse.change': warehouseChange
        }
    };
    exports.default = template;
    async function companyChange(def, comp) {
        let ctrl = this.$ctrl;
        await ctrl.$invoke('setCompany', { Id: comp.Id });
        ctrl.$toast('@[Default.Company.Changed]', "success");
    }
    async function warehouseChange(def, wh) {
        let ctrl = this.$ctrl;
        await ctrl.$invoke('setWarehouse', { Id: wh.Id });
        ctrl.$toast('@[Default.Warehouse.Changed]', "success");
    }
});
