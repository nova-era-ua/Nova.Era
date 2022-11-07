define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TItem.$Title'() { return `@[Item] [${this.Id ? this.Id : '@[NewItem]'}]`; },
            'TItem.$HasVariants'() { return this.Variants.length > 0; }
        },
        defaults: {
            'Item.Role'() { return this.ItemRoles.$isEmpty ? undefined : this.ItemRoles[0]; }
        },
        validators: {
            'Item.Name': '@[Error.Required]',
            'Item.Role': '@[Error.Required]',
            'Item.Unit': '@[Error.Required]'
        },
        commands: {
            addHierarchy,
            generateBarcode,
            addVariant,
            editVariant
        },
        delegates: {
            fetchUnit
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
    function fetchUnit(item, text) {
        if (!text)
            return [];
        return this.$ctrl.$invoke('fetch', { Text: text }, '/catalog/unit');
    }
    function generateBarcode(item) {
    }
    async function addVariant(item) {
        const ctrl = this.$ctrl;
        if (!item.Id) {
            this.$setDirty(true);
            await ctrl.$save();
        }
        let vars = await ctrl.$showDialog('/catalog/item/createvariant', { Id: item.Id });
        console.dir(vars);
    }
    async function editVariant(variant) {
        const ctrl = this.$ctrl;
        let result = await ctrl.$showDialog('/catalog/item/editvariant', { Id: variant.Id });
        console.dir(result);
    }
});
