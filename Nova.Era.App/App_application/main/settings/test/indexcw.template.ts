
const template: Template = {
	properties: {
		'TRoot.$IntVal': Number
	},
	delegates: {
		filter
	}
};

export default template;

function filter(this:IRoot, elem, filter) {
	//console.log(this, elem, filter);
	return elem.Code.toLowerCase().indexOf(filter.Fragment.toLowerCase()) !== -1;
}

