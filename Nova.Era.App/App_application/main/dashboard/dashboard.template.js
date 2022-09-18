define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const tu = require('std:utils').text;
    const template = {
        properties: {
            'TRoot.$$EditMode': Boolean,
            'TDashboard.$$Text': String,
            'TDashboard.$Items'() { return []; },
            'TDashboard.$Widgets': filteredWidgets
        },
        commands: {
            startEdit() { this.$$EditMode = true; },
            cancelEdit() { this.$$EditMode = false; this.$ctrl.$reload(); },
            endEdit: {
                exec: endEdit,
                canExec() { return this.$dirty; }
            }
        }
    };
    exports.default = template;
    function filteredWidgets() {
        if (!this.$$Text)
            return this.Widgets;
        let fi = this.Widgets.filter(x => tu.containsText(x, 'Name', this.$$Text));
        console.dir(fi);
        return fi;
    }
    async function endEdit() {
        let ctrl = this.$ctrl;
        await ctrl.$save();
        this.$$EditMode = false;
    }
});
