define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
            'TAccount.$Icon'() { return 'account-folder'; },
            'TAccount.$IsPlan'() { return this.Plan === 0; }
        },
        commands: {
            createPlan,
            createAccount: {
                exec: createAccount,
                canExec(parent) { return !!parent; }
            },
            edit: {
                exec: editAccount,
                canExec(item) { return !!parent; }
            }
        }
    };
    exports.default = template;
    async function createPlan() {
        const ctrl = this.$ctrl;
        let plan = await ctrl.$showDialog('/accounting/plan/editPlan');
        let newplan = this.Accounts.$append(plan);
        newplan.$select(this.Accounts);
    }
    async function createAccount(parent) {
        if (!parent)
            return;
        const ctrl = this.$ctrl;
        await ctrl.$expand(parent, 'Items', true);
        let acc = await ctrl.$showDialog('/accounting/plan/edit', null, { Parent: parent.Id });
        let newacc = parent.Items.$append(acc);
        newacc.$select(this.Accounts);
    }
    async function editAccount(item) {
        if (!item)
            return;
        const ctrl = this.$ctrl;
        if (item.$IsPlan) {
            let plan = await ctrl.$showDialog('/accounting/plan/editPlan', { Id: item.Id });
            item.$merge(plan);
        }
        else {
            let acc = await ctrl.$showDialog('/accounting/plan/edit', { Id: item.Id });
            item.$merge(acc);
        }
    }
});
