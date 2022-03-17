define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$Filter': String,
            'TFolder.$IsSearch'() { return this.Id === -1; },
            'TFolder.$IsFolder'() { return this.Id !== -1; },
            'TFolder.$IsVisible'() {
                return this.$IsFolder || !!this.$root.$Filter;
            }
        }
    };
    exports.default = template;
});
