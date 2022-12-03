// navpane.top

const eventBus: EventBus = require('std:eventBus');

const template: Template = {
	properties: {
		'TRoot.$Badge'() {return '' }
	},
	commands: {
		showNotify
	},
	events: {
		'Model.load': modelLoad
	}
}

export default template;

function showNotify() {
	let ctrl: any = this.$ctrl;

	ctrl.$showSidePane('notification');
}

function modelLoad() {
	let ctrl: IController = this.$ctrl;

	let update = async () => {
		let res = await ctrl.$invoke('updateNavPane', null, null, { hideIndicator: true });
		this.Notify.Count = res.Notify.Count;
	}
	setInterval(update, 30000); // 30 sec

	eventBus.$on('app.notify.update', update);
}