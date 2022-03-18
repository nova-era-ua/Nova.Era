define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TFolder.$Title'() { return this.Id ? this.Id : '@[NewFolder]'; }
        },
        validators: {
            'Folder.Name': "notBlank"
        },
        defaults: {
            'Folder.ParentFolder'() { return this.ParentFolder.Id; }
        }
    };
    exports.default = template;
});
