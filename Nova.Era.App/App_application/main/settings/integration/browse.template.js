define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const tu = require('std:utils').text;
    const template = {
        properties: {
            'TSource.$Category': category,
            'TSource.IntName': intName
        },
        delegates: {
            filter
        }
    };
    exports.default = template;
    function category() {
        switch (this.Key) {
            case 'Delivery': return '@[Int.Delivery]';
        }
        return this.Key;
    }
    function intName() {
        let arr = this.$root.Sources;
        return arr.$selected ? arr.$selected.Name : '';
    }
    function filter(elem, filter) {
        return tu.containsText(elem, "Name", filter.Text);
    }
});
