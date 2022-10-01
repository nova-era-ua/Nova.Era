define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("document/_common/index.module");
    const bind = require("document/_common/bind.module");
    const utils = require("std:utils");
    const template = {
        properties: {
            'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name; },
            'TDocument.$PaymentHtml': bind.bindSum("Payment"),
            'TDocument.$ShipmentHtml': bind.bindSum("Shipment")
        },
        events: {
            'app.document.link': handleLink
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function handleLink(elem) {
        let doc = this.Documents.find(doc => doc.Id === elem.Id);
        if (!doc)
            return;
        console.dir(elem.LinkedDocs);
        doc.LinkedDocs.$copy(elem.LinkedDocs);
    }
});
