
const template: Template = {
	properties: {
		'TAccount.$Name'() { return `${this.Code} ${this.Name}`;},
		'TRepData.$DtStart': total('DtStart'),
		'TRepData.$CtStart': total('CtStart'),
		'TRepData.$DtEnd': total('DtEnd'),
		'TRepData.$CtEnd': total('CtEnd')
	},
	commands: {
		clearFilter
	}
};

export default template;

function total(prop) {
	return function () {
		return this.Items.reduce((p, c) => p + c[prop], 0);
	};
}

function clearFilter(filter) {
	filter.Company.Id = -1;
	filter.Company.Name = '';
}
