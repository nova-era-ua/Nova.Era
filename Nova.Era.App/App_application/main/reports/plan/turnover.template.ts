const base: Template = require("reports/_common/simple.module");

const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TAccount.$Name'() { return `${this.Code} ${this.Name}`;},
		'TRepData.$DtStart': total('DtStart'),
		'TRepData.$CtStart': total('CtStart'),
		'TRepData.$DtEnd': total('DtEnd'),
		'TRepData.$CtEnd': total('CtEnd')
	}
};

export default utils.mergeTemplate(base, template);

function total(prop) {
	return function () {
		return this.Items.reduce((p, c) => p + c[prop], 0);
	};
}
