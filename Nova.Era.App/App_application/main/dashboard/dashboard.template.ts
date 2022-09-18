
const tu: UtilsText = require('std:utils').text;

const template: Template = {
	properties: {
		'TRoot.$$EditMode': Boolean,
		'TDashboard.$$Text': String,
		'TDashboard.$Items'() { return []; },
		'TDashboard.$Widgets': filteredWidgets
	},
	commands: {
		startEdit(this: any) { this.$$EditMode = true; },
		cancelEdit(this: any) { this.$$EditMode = false; this.$ctrl.$reload(); },
		endEdit: {
			exec: endEdit,
			canExec() { return this.$dirty; }
		}
	}
}

export default template;

function filteredWidgets() {
	if (!this.$$Text)
		return this.Widgets;
	let fi = this.Widgets.filter(x => tu.containsText(x, 'Name', this.$$Text));
	console.dir(fi);
	return fi;
}

async function endEdit(this: any) {
	let ctrl: IController = this.$ctrl;
	await ctrl.$save();
	this.$$EditMode = false;
}