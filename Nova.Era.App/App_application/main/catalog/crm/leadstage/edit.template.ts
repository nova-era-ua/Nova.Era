
const mod = require('/catalog/crm/leadstage/_stage.module')

const template: Template = {
	properties: {
		'TStage.$Id'() { return this.Id || '@[NewItem]' },
		'TStage.$Kind'() { return mod.kind2Text(this.Kind); },
		'TStage.$IsOnce'() { return this.Kind === 'S' || this.Kind === 'I'; }
	},
	validators: {
		'Stage.Name': '@[Error.Required]',
	},
	defaults: {
		"Stage.Order"(this: any) { return this.Params.NextOrdinal; },
		"Stage.Kind": 'P'
	}
};

export default template;

