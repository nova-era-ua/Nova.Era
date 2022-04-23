

const template: Template = {
	properties: {
		'TRoot.$SelectedElem': hasSelectedElem,
	},
	events: {
	},
	commands: {
	}
}

export default template;

function hasSelectedElem() {
	let sel = this.Groups.$selected;
	if (!sel) return undefined;
	return sel.Elements.$selected?.Id;
}
