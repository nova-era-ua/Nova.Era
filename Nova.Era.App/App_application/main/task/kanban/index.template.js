define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        options: {},
        properties: {},
        validators: {},
        commands: {
            addTask,
            openTask,
            test
        },
        delegates: {
            dropTask
        }
    };
    exports.default = template;
    function addTask(state) {
        alert('add card to state ' + state.Id);
    }
    async function dropTask(task, state) {
        let ctrl = this.$ctrl;
        let res = await ctrl.$invoke('setTaskState', { Id: task.Id, state: state.Id });
        task.State.$merge(res.State);
    }
    function openTask(task) {
        alert(task.Id);
    }
    function test() {
        alert('test');
    }
});
