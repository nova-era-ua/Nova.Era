define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const utils = require("std:utils");
    const tu = utils.text;
    const template = {
        options: {
            bindOnce: ['Countries', '$Countries']
        },
        properties: {
            'TRoot.Countries'() { return this.$Countries.$checked; },
            'TRoot.$CheckedList'() { return this.$Countries.$checked.map(x => x.Name).join(', '); }
        },
        events: {
            "Model.load": modelLoad,
        },
        commands: {
            addElements: {
                exec: addElements,
                canExec(coll) { return coll.length > 0; }
            }
        },
        delegates: {
            filter
        }
    };
    exports.default = template;
    function modelLoad() {
        setTimeout(async () => {
            const ctrl = this.$ctrl;
            let res = await ctrl.$invoke('download');
            if (res.success) {
                this.$Countries.$append(res.List);
                this.$Countries[0].$select();
            }
            else
                alert(res.error);
        }, 50);
    }
    function filter(item, filter) {
        if (!filter.Fragment)
            return true;
        return tu.containsText(item, "Id,Name,Alpha2,Alpha3", filter.Fragment);
    }
    async function addElements(coll) {
        let ctrl = this.$ctrl;
        await ctrl.$save();
        ctrl.$modalClose(true);
    }
});
