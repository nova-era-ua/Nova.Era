
const mod = require('/catalog/docstate/_state.module')

const template: Template = {
	properties: {
		'TForm.$CreateArg'() { return { Form: this.Id }; },
		'TState.$Kind'() { return mod.kind2Text(this.Kind); }
	},
	defaults: {
	},
	validators: {
	}
};

export default template;

