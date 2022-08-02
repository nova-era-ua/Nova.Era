
const template: Template = {
	commands: {
		addFromSite
	}
};

export default template;

async function addFromSite() {
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$showDialog('/catalog/country/download');
	ctrl.$reload();
}