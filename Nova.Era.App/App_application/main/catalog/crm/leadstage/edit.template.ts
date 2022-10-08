

const template: Template = {
	properties: {
		'TStage.$Id'() { return this.Id || '@[NewItem]' },
	},
	validators: {
		'Stage.Name': '@[Error.Required]',
	},
	defaults: {
		"Stage.Order"(this: any) { return this.Params.NextOrdinal; }
	}
};

export default template;

