

const template: Template = {
	properties: {
		'TItem.$Title'() { return `@[Item] [${this.Id ? this.Id : '@[NewItem]'}]`; },
	},
	validators: {
		'Item.Name': '@[Error.Required]',
	},
	commands: {
	},
	delegates: {
	}
};

export default template;

