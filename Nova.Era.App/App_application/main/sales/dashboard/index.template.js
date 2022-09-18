define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        events: {
            "Model.load": modelLoad
        }
    };
    exports.default = template;
    async function modelLoad() {
        console.dir('start');
        let arr = [
            '/_page/widgets/widget3/index/1004?Row=1&Col=1',
            '/_page/widgets/widget2/index/1004?Row=1&Col=1',
            '/_page/widgets/widget1/index/1004?Row=1&Col=1',
            '/_page/widgets/widget4/index/1004?Row=1&Col=1',
            '/_page/widgets/widget3/index/1004?Row=1&Col=1',
            '/_page/widgets/widget1/index/1004?Row=1&Col=1',
            '/_page/widgets/widget2/index/1004?Row=1&Col=1',
        ];
        let h = {
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json, text/html'
        };
        for (let i = 0; i < arr.length; i++) {
            let url = arr[i];
            await fetch(url, {
                method: 'GET',
                mode: 'same-origin',
                headers: h
            });
        }
    }
});
