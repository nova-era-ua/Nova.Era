define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        options: {},
        properties: {},
        commands: {
            createTest
        }
    };
    exports.default = template;
    async function createTest() {
        const ctrl = this.$ctrl;
        await ctrl.$invoke('createTest');
        ctrl.$toast('Тестове середовище створено', "success");
    }
});
