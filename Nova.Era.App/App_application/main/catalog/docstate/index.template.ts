
const template: Template = {
	options: {
		persistSelect: ['Forms']
	},
	commands: {
		editSelected: {
			exec: editSelected,
			canExec(arr) { return arr.$hasSelected; }
		}
	}
};

export default template;


async function editSelected(arr) {
	const ctrl: IController = this.$ctrl;
	let url = '/catalog/docstate/edit'
	let sel = arr.$selected;
	if (!sel)
		return;
	await ctrl.$showDialog(url, sel);
	ctrl.$reload();
}