define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TItemRole.$Id'() { return this.Id || '@[NewItem]'; },
            'TRoleAccount.$PlanArg'() { return { Plan: this.Plan.Id }; }
        },
        defaults: {},
        validators: {
            'ItemRole.Name': '@[Error.Required]'
        }
    };
    exports.default = template;
});
