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
            'TItemRole.$HasCostItem'() { return this.Kind !== 'Money'; }
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
            'ItemRole.Kind.change': kindChange,
            'ItemRole.Accounts[].add': rowAdd
        },
        delegates: {
            fetchByPlan
        }
    };
    exports.default = template;
    function kindChange(role, kind) {
        if (kind === 'Money') {
            if (!role.ExType)
                role.ExType = 'C';
        }
        else {
            role.ExType = '';
        }
    }
    function rowAdd(arr, elem) {
        let ix = arr.indexOf(elem);
        if (ix < 1)
            return;
        let prev = arr[ix - 1];
        elem.Plan.$merge(prev.Plan);
    }
    function fetchByPlan(acc, text) {
        let ctrl = this.$ctrl;
        return ctrl.$invoke('fetch', { Plan: acc.$parent.Plan.Id, Text: text }, '/catalog/account');
    }
});
