define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const barcode = require('std:barcode');
    const template = {
        commands: {
            generateBarcode
        }
    };
    exports.default = template;
    async function generateBarcode(item) {
        item.Barcode = barcode.generateEAN13('20', item.Id);
    }
});
