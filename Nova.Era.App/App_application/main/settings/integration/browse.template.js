define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$Name': String,
            'TRoot.$SelectedName'() { return this.Sources.$selected ? this.Sources.$selected.Name : ''; },
            'TSource.$Image': image,
            'TSource.$Category': category,
            'TSource.IntName'() { return this.$root.$Name || this.Name; }
        }
    };
    exports.default = template;
    function category() {
        switch (this.Key) {
            case 'Delivery': return '@[Int.Delivery]';
        }
        return this.Key;
    }
    function image() {
        return `<img src="${this.Logo}" height="40px">`;
    }
});
