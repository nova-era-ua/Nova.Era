define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TPrintForm.$ReportUrl': reportUrl
        },
        commands: {
            testAtt
        }
    };
    function reportUrl() {
        return `/report/show/${this.DocumentId}?base=${this.Url}&rep=${this.Report}`;
    }
    exports.default = template;
    async function testAtt() {
        let ctrl = this.$ctrl;
        let res = await ctrl.$invoke('attachReport', { Base: 'document/print', Report: 'waybillout', Id: this.PrintForms.$selected.DocumentId });
        alert(JSON.stringify(res));
    }
});
