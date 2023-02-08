define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TAgent.$Title'() { return this.Id || '@[NewItem]'; },
        },
        validators: {
            'Agent.Name': '@[Error.Required]'
        },
        commands: {
            addContact
        },
        delegates: {
            tagSettings
        }
    };
    exports.default = template;
    async function addContact() {
        const ctrl = this.$ctrl;
        let ag = this.Agent;
        let contact = await ctrl.$showDialog('/catalog/contact/browse');
        if (ag.Contacts.find(c => c.Id === contact.Id))
            return;
        ag.Contacts.$append(contact);
    }
    async function tagSettings(items) {
        const ctrl = this.$ctrl;
        let tags = await ctrl.$showDialog('/catalog/tag/settings', null, { For: ' Agent' });
    }
});
