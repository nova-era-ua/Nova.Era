define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$changing': Boolean,
            'TPolicy.$AccPlanRemsVisible'() { return this.CheckRems === 'A'; },
            'TAccount.$Title'() { return this.Id ? `${this.Name} [${this.Code}]` : ''; }
        },
        validators: {
            'Policy.AccPlanRems': {
                valid: "notBlank",
                applyIf(elem) { return elem.$AccPlanRemsVisible; },
                msg: '@[Error.Required]'
            }
        },
        commands: {
            startChanging() { this.$changing = true; },
            cancelChanging
        }
    };
    exports.default = template;
    function cancelChanging() {
        this.$ctrl.$reload();
    }
});
