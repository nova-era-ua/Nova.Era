define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        options: {},
        events: {
            'Model.load': modelLoad
        },
        commands: {
            addItem
        }
    };
    exports.default = template;
    function modelLoad() {
        if (this.Groups.length)
            this.Groups[0].$expand();
    }
    async function addItem() {
        let parent = this.Groups.$selected;
        if (!parent)
            return;
        const ctrl = this.$ctrl;
        await ctrl.$expand(parent, 'Items', true);
        let group = await ctrl.$showDialog('/catalog/itemgroup/edit', null, { Parent: parent.Id });
        let newgroup = parent.Items.$append(group);
        newgroup.$select(this.Groups);
    }
});
