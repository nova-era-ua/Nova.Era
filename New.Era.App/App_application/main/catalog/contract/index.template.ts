// contract.index.template

const template: Template = {
	commands: {
		clearFilter
	}
};

export default template;

function clearFilter(elem) {
	elem.Id = 0;
	elem.Name = '';
}