
const template: Template = {
	properties: {
		'TRoot.$changing': Boolean,
		'TPolicy.$AccPlanRemsVisible'() { return this.CheckRems === 'A' },
		'TAccount.$Title'() { return this.Id ? `${this.Name} [${this.Code}]` : ''; }
	},
	validators: {
		'Policy.AccPlanRems': {
			valid: StdValidator.notBlank,
			applyIf(elem: any) { return elem.$AccPlanRemsVisible; },
			msg:'@[Error.Required]'
		}
	},
	commands: {
		startChanging(this: any) { this.$changing = true; },
		cancelChanging
	}
}

export default template;

function cancelChanging() {
	this.$ctrl.$reload();
}