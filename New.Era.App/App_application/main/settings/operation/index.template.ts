const template: Template = {
	properties: {
		'TRoot.$CreateData'() { return { Parent: this.Menu.$selected?.Id };}
	},
	validators: {
	}
};

export default template;