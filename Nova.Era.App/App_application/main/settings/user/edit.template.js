define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        validators: {
            'User.UserName': '@[Error.Required]',
            'User.PersonName': '@[Error.Required]'
        },
        commands: {
            create
        }
    };
    exports.default = template;
    async function create(user) {
        const ctrl = this.$ctrl;
        let newuser = await ctrl.$invoke("createUser", { User: user });
    }
});
