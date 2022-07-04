define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TPrintForm.$ReportUrl': reportUrl
        }
    };
    function reportUrl() {
        return `/report/show/${this.DocumentId}?base=${this.Url}&rep=${this.Report}`;
    }
    exports.default = template;
});
