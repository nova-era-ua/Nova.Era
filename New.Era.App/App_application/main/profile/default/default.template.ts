
const template: Template = {
	events: {
		'Default.Company.change': companyChange,
		'Default.Warehouse.change': warehouseChange
	}
}

export default template;

async function companyChange(def, comp) {
	let ctrl: IController = this.$ctrl;
	await ctrl.$invoke('setCompany', { Id: comp.Id });
	ctrl.$toast('@[Default.Company.Changed]', CommonStyle.success);
}

async function warehouseChange(def, wh) {
	let ctrl: IController = this.$ctrl;
	await ctrl.$invoke('setWarehouse', { Id: wh.Id });
	ctrl.$toast('@[Default.Warehouse.Changed]', CommonStyle.success);
}