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
	if (note.Done) {
		note.Done = true;
		eventBus.$emit('app.notify.dec');
	}
	if (note.Link && note.LinkUrl)
		ctrl.$showDialog(note.LinkUrl, {Id: note.Link});
}

function deleteNotify(note) {
	alert(note.Id);
}