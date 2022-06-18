const template: Template = {
	options: {
		persistSelect:['Menu']
	},
	properties: {
		'TRoot.$CreateData'() { return { Parent: this.Menu.$selected?.Id };}
	},
	validators: {
	}
};

export default template;