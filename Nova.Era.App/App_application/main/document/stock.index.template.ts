// stock.index

const base: Template = require("document/_common/index.module");
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name; }
	}
};

export default utils.mergeTemplate(base, template);

