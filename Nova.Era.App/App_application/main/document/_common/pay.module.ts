
const base: Template = require('/document/_common/common.module');
const utils: Utils = require("std:utils");

// common module for pay documents

const template: Template = {
	properties: {
		'TDocument.$CompanyArg'() { return { Company: this.Company?.Id }; },
	}
};

export default utils.mergeTemplate(base, template);
