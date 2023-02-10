define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const dateUtils = require("std:utils").date;
    const template = {
        properties: {
            'TLead.$Id'() { return this.Id ? this.Id : '@[NewItem]'; }
        },
        validators: {
            'Lead.Name': '@[Error.Required]',
            'Lead.Stage': '@[Error.Required]'
        },
        defaults: {
            'Lead.Stage'() { return this.Stages.find(x => x.Kind === 'I'); }
        },
        delegates: {
            tagSettings
        }
    };
    exports.default = template;
    async function tagSettings() {
        const ctrl = this.$ctrl;
        let tags = await ctrl.$showDialog('/catalog/tag/settings', null, { For: 'Lead' });
        this.Tags.$copy(tags);
        this.Lead.Tags.forEach(lt => {
            let nt = tags.find(t => t.Id == lt.Id);
            if (nt)
                lt.$merge(nt);
        });
    }
});
