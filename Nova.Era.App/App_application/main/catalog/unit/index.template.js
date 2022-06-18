define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        options: {
            persistSelect: ['Units']
        },
        commands: {
            addFromCatalog
        }
    };
    exports.default = template;
    async function addFromCatalog() {
        let ctrl = this.$ctrl;
        let result = await ctrl.$showDialog('/catalog/unit/browsecatalog');
        if (!result)
            return;
        let ids = result.map(c => '' + c.Id).join(',');
        await ctrl.$invoke('addFromCatalog', { Ids: ids });
        await ctrl.$reload(this.Units);
    }
});
