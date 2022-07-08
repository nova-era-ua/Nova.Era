define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TItemRole.$Id'() { return this.Id || '@[NewItem]'; },
            'TRoleAccount.$PlanArg'() { return { Plan: this.Plan.Id }; },
            'TItemRole.$HasStock'() { return this.Kind === 'Item'; }
        },
        defaults: {
            'ItemRole.Kind': 'Item'
        },
        validators: {
            'ItemRole.Name': '@[Error.Required]',
            'ItemRole.Accounts[].Plan': '@[Error.Required]',
            'ItemRole.Accounts[].AccKind': '@[Error.Required]',
            'ItemRole.Accounts[].Account': '@[Error.Required]'
        }
    };
    exports.default = template;
});
