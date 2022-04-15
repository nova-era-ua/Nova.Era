define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const URLS = {
        editPlan: '/settings/accountplan/editPlan',
        edit: '/settings/accountplan/edit'
    };
    const template = {
        properties: {
            'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
            'TAccount.$Icon'() { return this.IsFolder ? 'account-folder' : 'account'; },
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
        let plan = await ctrl.$showDialog(URLS.editPlan);
        let newplan = this.Accounts.$append(plan);
        newplan.$select(this.Accounts);
    }
    async function createAccount(parent) {
        if (!parent)
            return;
        const ctrl = this.$ctrl;
        await ctrl.$expand(parent, 'Items', true);
        let acc = await ctrl.$showDialog(URLS.edit, null, { Parent: parent.Id });
        let newacc = parent.Items.$append(acc);
        newacc.$select(this.Accounts);
    }
    function mergeProps(trg, src) {
        trg.Name = src.Name;
        trg.Code = src.Code;
        trg.IsFolder = src.IsFolder;
    }
    async function editAccount(item) {
        if (!item)
            return;
        const ctrl = this.$ctrl;
        if (item.$IsPlan) {
            let plan = await ctrl.$showDialog(URLS.editPlan, { Id: item.Id });
            mergeProps(item, plan);
        }
        else {
            let acc = await ctrl.$showDialog(URLS.edit, { Id: item.Id });
            mergeProps(item, acc);
        }
    }
});
