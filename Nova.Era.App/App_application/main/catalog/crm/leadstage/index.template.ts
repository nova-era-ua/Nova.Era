
const mod = require('/catalog/crm/leadstage/_stage.module')

const template: Template = {
	properties: {
		'TStage.$Kind'() { return mod.kind2Text(this.Kind); }
	},
};

export default template;


