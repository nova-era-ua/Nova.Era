
const template: Template = {
	commands: {
		clearFilter
	}
};

export default template;

function clearFilter(filter) {
	filter.Id = -1;
	filter.Name = '';
}
