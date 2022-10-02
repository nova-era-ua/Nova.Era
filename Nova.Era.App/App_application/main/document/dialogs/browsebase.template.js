define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const bind = require("document/_common/bind.module");
    const template = {
        properties: {
            'TDocument.$PaymentHtml': bind.bindSum("Payment"),
            'TDocument.$ShipmentHtml': bind.bindSum("Shipment")
        }
    };
    exports.default = template;
});
