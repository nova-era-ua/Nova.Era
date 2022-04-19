

const template: Template = {
	options: {
		persistSelect:['Currencies']
	},
	commands: {
		addFromCatalog
	}
};

export default template;


async function addFromCatalog() {
	let ctrl: IController = this.$ctrl;
	let result = await ctrl.$showDialog('/catalog/currency/browsecatalog');
	if (!result)
		return;
	let ids = result.map(c => '' + c.Id).join(',');
	await ctrl.$invoke('addFromCatalog', { Ids: ids });
	await ctrl.$reload(this.Currencies);

}