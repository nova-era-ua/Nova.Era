define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$$Tab': String,
            'TOperation.$Title'() { return this.Id ? this.Id : '@[NewItemW]'; }
        },
        defaults: {
            "Operation.Menu"() { return this.Params.ParentMenu; }
        },
        validators: {
            'Operation.Form': '@[Error.Required]',
            'Operation.Name': '@[Error.Required]',
            'Operation.Journals[].Id': '@[Error.Required]'
        },
        events: {
            'Operation.Form.change': formChange
        }
    };
    exports.default = template;
    function formChange(op) {
        let rk = (op.Form.RowKinds || '').split(',');
        let jrnStore = rk.map(k => { return { RowKind: k }; });
        op.JournalStore.$empty();
        op.JournalStore.$append(jrnStore);
    }
});
