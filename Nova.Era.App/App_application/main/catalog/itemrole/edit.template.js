define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TItemRole.$Id'() { return this.Id || '@[NewItem]'; },
            'TRoleAccount.$PlanArg'() { return { Plan: this.Plan.Id }; },
            'TItemRole.$HasStock'() { return this.Kind === 'Item'; },
            'TItemRole.$HasMoneyType'() { return this.Kind === 'Money'; },
        },
        defaults: {
            'ItemRole.Kind': 'Item'
        },
        validators: {
            'ItemRole.Name': '@[Error.Required]',
            'ItemRole.Accounts[].Plan': '@[Error.Required]',
            'ItemRole.Accounts[].AccKind': '@[Error.Required]',
            'ItemRole.Accounts[].Account': '@[Error.Required]'
        },
        events: {
            'ItemRole.Kind.change': kindChange
        }
    };
    exports.default = template;
    function kindChange(role, kind) {
        if (kind === 'Money' && !role.ExType)
            role.ExType = 'C';
    }
});
