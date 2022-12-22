define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const htmlTool = require("std:html");
    const template = {
        commands: {
            addElement,
            removeElement,
            testFetch,
            testInvoke,
            testQueue,
            testPrint,
            showInline() { this.$ctrl.$inlineOpen('testClr'); }
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
    async function testFetch() {
        let url = 'https://hola.com/api/auth/';
        let params = {
            body: JSON.stringify({ login: 'user', password: '12345678' }),
            headers: { ContentType: 'application/json' },
            method: 'post'
        };
        try {
            let resp = await fetch(url, params);
            console.dir(resp);
        }
        catch (err) {
            console.dir(err);
        }
    }
    async function testInvoke() {
        let ctrl = this.$ctrl;
        try {
            let res = await ctrl.$invoke('testapi', null, null, { catchError: true });
            alert(JSON.stringify(res));
        }
        catch (err) {
            alert('catched: ' + err.message);
        }
    }
    async function testQueue() {
        let ctrl = this.$ctrl;
        try {
            await ctrl.$invoke('testqueue', null, null, { catchError: true });
        }
        catch (err) {
            alert('catched: ' + err);
        }
    }
    function testPrint() {
        debugger;
        htmlTool.printDirect('/file/test.pdf');
    }
});
