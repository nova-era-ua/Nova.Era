define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const tu = require('std:utils').text;
    const URLS = {
        editPlan: '/settings/accountplan/editPlan',
        edit: '/settings/accountplan/edit'
    };
    const template = {
        properties: {
            'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
            'TAccount.$Icon'() { return this.IsFolder ? 'account-folder' : 'account'; },
            'TAccount.$IsPlan'() { return this.Plan === 0; },
            'TRoot.$Search': String,
            'TRoot.$Tree'() { return { Items: this.Accounts }; }
        },
        events: {
            'Root.$Search.change': searchAccount,
        },
        commands: {
            createPlan,
            createAccount: {
                exec: createAccount,
                canExec(parent) { return parent && parent.IsFolder; }
            },
            edit: {
                exec: editAccount,
                canExec(item) { return !!parent; }
            },
            delete: {
                exec: deleteAccount,
                canExec: canDeleteAccount,
                confirm: '@[Confirm.Delete.Element]'
            },
            setRemAccount
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
    async function deleteAccount(item) {
        if (!item || item.Items.length)
            return;
        const ctrl = this.$ctrl;
        await ctrl.$invoke('deleteItem', { Id: item.Id });
        item.$remove();
    }
    function canDeleteAccount(item) {
        return item && !item.Items.length;
    }
    function searchAccount(root, text) {
        if (!text)
            return;
        let found = root.Accounts.$find(el => el.Code.indexOf(text) === 0 || tu.contains(el.Name, text));
        if (found)
            found.$select(root.Accounts);
        else
            root.$Search = '';
    }
    async function setRemAccount() {
        const ctrl = this.$ctrl;
        let acc = await ctrl.$showDialog('/catalog/account/browseall');
        alert(acc.Id);
    }
});
