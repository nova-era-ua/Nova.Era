
const template: Template = {
	events: {
		'Default.Company.change': companyChange,
		'Default.Warehouse.change': warehouseChange,
		'Default.RespCenter.change': respCenterChange,
		'Default.Period.change': periodChange
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

async function respCenterChange(def, resp) {
	let ctrl: IController = this.$ctrl;
	await ctrl.$invoke('setRespCenter', { Id: resp.Id });
	ctrl.$toast('@[Default.RespCenter.Changed]', CommonStyle.success);
}

async function periodChange(def, period) {
	let ctrl: IController = this.$ctrl;
	await ctrl.$invoke('setPeriod', { From: period.From, To:period.To });
	ctrl.$toast('@[Default.Period.Changed]', CommonStyle.success);
}

