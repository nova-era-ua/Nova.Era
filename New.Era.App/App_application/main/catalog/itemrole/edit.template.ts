

const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TItemRole.$Id'() { return this.Id || '@[NewItem]' },
		'TRoleAccount.$PlanArg'() { return {Plan: this.Plan.Id}; }
	},
	defaults: {
	},
	validators: {
		'ItemRole.Name': '@[Error.Required]'
	}
};

export default template;

