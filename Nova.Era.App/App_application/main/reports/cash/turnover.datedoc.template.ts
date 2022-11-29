const utils: Utils = require("std:utils");
const du: UtilsDate = utils.date;


const base: Template = require("reports/_common/simple.module");

const template: Template = {
	properties: {
		'TRepData.$DocName'() {return `${this.OperationName} # ${this.No}` },
		'TRepData.$Name'() { return this.$level === 1 ? du.formatDate(this.Date) : this.$DocName; },
	}
};

export default utils.mergeTemplate(base, template);

