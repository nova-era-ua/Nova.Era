define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TItem.$Title'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        defaults: {
            'Item.Role'() { return this.ItemRoles.$isEmpty ? undefined : this.ItemRoles[0]; }
        },
        validators: {
            'Item.Name': '@[Error.Required]',
            'Item.Role': '@[Error.Required]'
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
        if (elems.find(h => h.Group === item.Id))
            return;
        elems.$append({ Group: item.Id, Path: makePath(item, ' > ') });
    }
});
