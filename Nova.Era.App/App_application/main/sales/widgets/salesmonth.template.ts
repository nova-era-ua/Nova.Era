
const utils = require('std:utils');
const du = utils.date;

const template: Template = {
	properties: {
		'TRoot.$Today': todayCount
	}
}

export default template;

function todayCount() {
	return 22;
}

