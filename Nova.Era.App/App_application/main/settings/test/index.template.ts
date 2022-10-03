
const template: Template = {
	commands: {
		addElement,
		removeElement
	} 
};

export default template;


function addElement(elem) {
	let x = elem.Items.$append({ Name: 'Child element' });
	x.$select(this.Accounts);
}
function removeElement(elem) {
	elem.$remove();
}