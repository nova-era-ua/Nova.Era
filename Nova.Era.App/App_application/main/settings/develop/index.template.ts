
const template: Template = {
	options: {
 	},
	properties: {
	},
	commands: {
		createTest
	} 
};

export default template;

async function createTest() {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('createTest');
	ctrl.$toast('Тестове середовище створено', CommonStyle.success)
}