define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const eventBus = require('std:eventBus');
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
        setInterval(async () => {
            let res = await ctrl.$invoke('updateNavPane', null, null, { hideIndicator: true });
            this.Notify.Count = res.Notify.Count;
        }, 30000);
        eventBus.$on('app.notify.dec', () => {
            if (this.Notify.Count)
                this.Notify.Count -= 1;
        });
    }
});
