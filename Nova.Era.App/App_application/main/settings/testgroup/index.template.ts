

const template: Template = {
	properties: {
	},
	commands: {
		testConfirm,
	} 
};

export default template;


async function testConfirm() {
	const ctrl: IController = this.$ctrl;
	var result = await ctrl.$confirm({
		msg: 'Confirm Message', title: 'Confirm title',
		list: ["item1", "item2", "item3"],
		buttons: [
			{ text: 'Button1', result: "Button1" },
			{ text: 'Button2', result: "Button2" },
			{ text: 'Cancel', result: false },
		]
	});
	alert(result);
}
