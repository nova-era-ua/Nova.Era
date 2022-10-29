define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TIntegration.$HlinkClass'() { return !this.Active ? 'not-active' : ''; },
            'TSource.$Category': category,
            'TRoot.$Integrations': allIntegrations
        },
        commands: {
            addIntegration
        },
        events: {
            'app.element.save': elementSaved,
            'app.element.delete': elementDeleted
        }
    };
    exports.default = template;
    function category() {
        switch (this.Id) {
            case 'Delivery': return '@[Int.Delivery]';
        }
        return this.Id;
    }
    function allIntegrations() {
        return this.Sources.reduce((p, c) => p.concat(c.Integrations), []);
    }
    async function addIntegration() {
        let ctrl = this.$ctrl;
        let src = await ctrl.$showDialog('/settings/integration/browse');
        let intg = await ctrl.$invoke('add', { Id: src.Id, Key: src.Key, Name: src.IntName });
        await ctrl.$reload();
        let found = this.$Integrations.find(el => el.Id === intg.Integration.Id);
        ctrl.$showDialog(found.SetupUrl, { Id: found.Id });
    }
    function elementSaved(elem) {
        let int = elem.Integration;
        let found = this.$Integrations.find(el => el.Id === int.Id);
        if (found) {
            found.Active = int.Active;
            found.Name = int.Name;
        }
    }
    function elementDeleted(elem) {
        this.$ctrl.$reload();
    }
});
