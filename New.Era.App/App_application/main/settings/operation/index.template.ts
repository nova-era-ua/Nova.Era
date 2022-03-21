const template: Template = {
	properties: {
		'TRoot.$CreateData'() { return { Parent: this.Groups.$selected?.Id };}
	},
	validators: {
	}
};

export default template;