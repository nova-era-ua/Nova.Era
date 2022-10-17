
const mod = require('/catalog/docstate/_state.module')

const template: Template = {
	properties: {
		'TState.$Id'() { return this.Id || '@[NewItem]' },
		'TState.$Kind'() { return mod.kind2Text(this.Kind); },
		'TState.$IsOnce'() { return this.Kind === 'S' || this.Kind === 'I'; }
	},
	validators: {
		'State.Name': '@[Error.Required]',
	},
	defaults: {
		"State.Kind": 'P',
		"State.Order"(this: any) { return this.Params.NextOrdinal; },
		'State.Form'(this: any) { return this.Params.Form; }
	}
};

export default template;

