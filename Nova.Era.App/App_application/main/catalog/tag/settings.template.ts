
// tag.settings
const template: Template = {
	properties: {
	},
	validators: {
		'Tags[].Name': '@[Error.Required]'
	},
	events: {
		'Tags[].add': tagAdd
	},
	commands: {
	}
};

export default template;


function tagAdd(tags, tag) {
	tag.For = this.Params.For;
}