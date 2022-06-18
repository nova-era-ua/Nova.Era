
const template: Template = {
	properties: {
		'TRepDataArray.$CrossNames': crossNames
	},
	commands: {
		clearFilter
	}
};

export default template;

function crossNames() {
	let wharr = this.$root.Warehouses;
	let arr = this.$cross.WhCross;
	return arr.map(x => wharr.find(w => w.Key === x)?.Name);
}

function clearFilter(filter) {
	filter.Company.Id = -1;
	filter.Company.Name = '';
}


