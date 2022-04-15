
const base: Template = require("document/_common/index.module");

const tmlUtils = require('std:tmlutils');

const template: Template = {
	properties: {
		'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name; }
	}
};

export default tmlUtils.mergeTemplate(base, template);

