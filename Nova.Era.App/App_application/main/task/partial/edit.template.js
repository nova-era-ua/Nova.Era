define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TTask.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        defaults: {
            'Task.LinkId'() { return this.Params.LinkId; },
            'Task.LinkType'() { return this.Params.LinkType; },
            'Task.LinkUrl'() { return this.Params.LinkUrl; },
            'Task.State'() { return this.States.length ? this.States[0] : null; }
        },
        validators: {}
    };
    exports.default = template;
});
