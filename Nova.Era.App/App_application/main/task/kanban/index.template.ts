// task.kanban
const template: Template = {
	options: {
	},
	properties: {
	},
	validators: {
	},
	commands: {
		addTask,
		openTask,
		test
	},
	delegates: {
		dropTask
	}
};

export default template;

function addTask(state) {
	alert('add card to state ' + state.Id);
}

async function dropTask(task, state) {
	let ctrl: IController = this.$ctrl;
	let res = await ctrl.$invoke('setTaskState', { Id: task.Id, state: state.Id });
	task.State.$merge(res.State);
}

function openTask(task) {
	alert(task.Id);
}

function test() {
	alert('test');
}