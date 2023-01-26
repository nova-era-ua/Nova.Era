
const template: Template = {
	commands: {
		createUser
	}
}

export default template;

async function createUser(users) {
	const ctrl: IController = this.$ctrl;
	let user = await ctrl.$showDialog("/settings/user/create");
}