const base: Template = require("reports/_common/simple.module");

const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRepDataArray.$CrossNames': crossNames
	}
};

export default utils.mergeTemplate(base, template);

function crossNames() {
	let wharr = this.$root.Warehouses;
	let arr = this.$cross.WhCross;
	return arr.map(x => wharr.find(w => w.Key === x)?.Name);
}


