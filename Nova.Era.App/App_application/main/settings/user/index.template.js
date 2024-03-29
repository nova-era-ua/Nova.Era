define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        commands: {
            createUser
        }
    };
    exports.default = template;
    async function createUser(users) {
        const ctrl = this.$ctrl;
        let user = await ctrl.$showDialog("/settings/user/create");
        console.dir(user);
        users.$append(user);
    }
});
