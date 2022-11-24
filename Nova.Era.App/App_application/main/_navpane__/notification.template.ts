// navpane.top

const template: Template = {
	properties: {
	},
	commands: {
		testInvoke
	}
}

export default template;

async function testInvoke() {
	let ctrl: IController = this.$ctrl;

	await ctrl.$invoke('getPrices', { Items: '100,200,201', PriceKind:5, Date: '20220101' }, '/document/sales/invoice', { hideIndicator: true });

}