// navpane.notification

const eventBus: EventBus = require('std:eventBus');

const template: Template = {
	properties: {
		'TNotify.$DoneIcon'() { return this.Done ? 'dot-blue' : 'circle'; }
	},
	commands: {
		clickNotify,
		deleteNotify
	}
}

export default template;

async function clickNotify(note) {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('done', { Id: note.Id })
	if (!note.Done) {
		note.Done = true;
		eventBus.$emit('app.notify.update');
	}
	if (note.Link && note.LinkUrl)
		ctrl.$showDialog(note.LinkUrl, {Id: note.Link});
}

async function deleteNotify(note) {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('delete', { Id: note.Id })
	note.$remove();
	eventBus.$emit('app.notify.update');
}