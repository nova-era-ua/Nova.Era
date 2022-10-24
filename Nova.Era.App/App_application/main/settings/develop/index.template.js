define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        commands: {
            createTest,
            upload,
            appList,
            uploadApp
        }
    };
    exports.default = template;
    async function createTest() {
        const ctrl = this.$ctrl;
        await ctrl.$invoke('createTest');
        ctrl.$toast('Тестове середовище створено', "success");
    }
    async function upload() {
        const ctrl = this.$ctrl;
        let result = await ctrl.$upload('/settings/develop/upload', 'application/zip');
        ctrl.$toast('Застосунок завантажено успішно', "success");
    }
    async function appList() {
        const ctrl = this.$ctrl;
        let result = await ctrl.$invoke('appList');
        console.dir(result);
    }
    async function uploadApp() {
        const ctrl = this.$ctrl;
        let result = await ctrl.$invoke('uploadApp', { FileName: "app1" });
        console.dir(result);
    }
});
