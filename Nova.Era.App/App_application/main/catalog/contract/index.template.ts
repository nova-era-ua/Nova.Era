// contract.index.template

const template: Template = {
	options: {
		persistSelect: ["Contracts"]
	},
	properties: {
		'TRoot.$CreateArg': createArg
	},
	commands: {
		clearFilter
	}
};

export default template;

function clearFilter(elem) {
	elem.Id = 0;
	elem.Name = '';
}

function createArg() {
	let filter = this.Contracts?.$ModelInfo?.Filter;
	let r: any = {};
	if (filter.Agent.Id)
		r.Agent = filter.Agent.Id;
	if (filter.Company.Id)
		r.Company = filter.Company.Id;
	return r;
}