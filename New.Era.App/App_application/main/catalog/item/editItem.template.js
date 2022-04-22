define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TItem.$Title'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Item.Name': '@[Error.Required]'
        },
        commands: {
            addHierarchy
        }
    };
    exports.default = template;
    async function addHierarchy(elems) {
        const ctrl = this.$ctrl;
        let item = await ctrl.$showDialog('/catalog/itemgroup/browse', null, { Hierarchy: elems.$parent.Id });
        function makePath(item, sep) {
            let p = item.$parent.$parent;
            if (p !== item.$root)
                return makePath(p, sep) + sep + item.Name;
            return item.Name;
        }
        elems.$append({ Id: 0, Path: makePath(item, ' > ') });
    }
});
