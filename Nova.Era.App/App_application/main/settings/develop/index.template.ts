
const template: Template = {
	commands: {
		createTest,
		upload,
		appList,
		uploadApp
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
	let result = await ctrl.$upload('/settings/develop/upload', 'application/zip')
	//alert(JSON.stringify(result));
	ctrl.$toast('Застосунок завантажено успішно', CommonStyle.success);
}

async function appList() {
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('appList');
	console.dir(result);
}

async function uploadApp() {
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('uploadApp', {FileName: "app1"});
	console.dir(result);
}