define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$Badge'() { return ''; }
        },
        commands: {
            showNotify
        },
        events: {
            'Model.load': modelLoad
        }
    };
    exports.default = template;
    function showNotify() {
        let ctrl = this.$ctrl;
        ctrl.$showSidePane('notification');
    }
    function modelLoad() {
        let ctrl = this.$ctrl;
    }
});
