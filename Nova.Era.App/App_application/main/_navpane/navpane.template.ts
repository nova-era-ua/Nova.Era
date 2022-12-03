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
	setInterval(async () => {
		let res = await ctrl.$invoke('updateNavPane', null, null, { hideIndicator: true });
		this.Notify.Count = res.Notify.Count;
	}, 30000); // 30 sec

	eventBus.$on('app.notify.dec', () => {
		if (this.Notify.Count)
			this.Notify.Count -= 1;
	});
}