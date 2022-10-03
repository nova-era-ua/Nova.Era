define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        commands: {
            addElement,
            removeElement
        }
    };
    exports.default = template;
    function addElement(elem) {
        let x = elem.Items.$append({ Name: 'Child element' });
        x.$select(this.Accounts);
    }
    function removeElement(elem) {
        elem.$remove();
    }
});
