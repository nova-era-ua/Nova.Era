define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]'; },
            'TOpTrans.$PlanArg'() { return { Plan: this.Plan.Id }; },
            'TOpTrans.$DtAccVisible'() { return this.Plan.Id && this.DtAccMode === ''; },
            'TOpTrans.$CtAccVisible'() { return this.Plan.Id && this.CtAccMode === ''; },
            'TOpTrans.$DtRoleVisible'() { return this.Plan.Id && this.DtAccMode === 'R'; },
            'TOpTrans.$CtRoleVisible'() { return this.Plan.Id && this.CtAccMode === 'R'; },
            'TOpLink.$Types': opLinkTypes
        },
        validators: {
            'Operation.Form': '@[Error.Required]',
            'Operation.Name': '@[Error.Required]',
            'Operation.OpLinks[].Operation': '@[Error.Required]',
            'Operation.OpLinks[].Category': '@[Error.Required]'
        },
        events: {
            'Operation.Form.change': formChange,
            'Operation.Trans[].DtAccMode.change'(elem) { elem.Dt.$empty(); },
            'Operation.Trans[].CtAccMode.change'(elem) { elem.Ct.$empty(); },
            'Operation.OpLinks[].add'(links, link) { link.Type = 'BySum'; }
        }
    };
    exports.default = template;
    function formChange() {
    }
    function opLinkTypes() {
        return [
            { Name: 'По сумі', Value: 'BySum' }
        ];
    }
});
