define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        commands: {
            cmd1
        }
    };
    exports.default = template;
    async function cmd1() {
        await this.$ctrl.$invoke('cmd1');
    }
});
