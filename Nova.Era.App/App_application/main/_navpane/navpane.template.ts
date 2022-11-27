// navpane.top

const template: Template = {
	properties: {
		'TRoot.$Badge'() {return '' }
	},
	commands: {
		showNotify
	},
	events: {
		'Model.load': modelLoad
	}
}

export default template;

function showNotify() {
	let ctrl: any = this.$ctrl;

	ctrl.$showSidePane('notification');
}

function modelLoad() {
	let ctrl: IController = this.$ctrl;
	/*
	setInterval(async () => {
		let res = await ctrl.$invoke('getPrices', { Items: '100,200,201', PriceKind: 5, Date: '20220101' }, '/document/sales/invoice', { hideIndicator: true });
		console.dir(res);
	}, 3000)
	*/
}