
const template: Template = {
	commands: {
		createTest,
		upload
	} 
};

export default template;

async function createTest() {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('createTest');
	ctrl.$toast('Тестове середовище створено', CommonStyle.success)
}

async function upload() {
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$upload('/settings/develop/upload', 'application/json')
	//alert(JSON.stringify(result));
	ctrl.$toast('Застосунок завантажено успішно', CommonStyle.success);
}