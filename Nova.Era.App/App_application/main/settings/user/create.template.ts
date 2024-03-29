﻿
// User.Create
const template: Template = {
	validators: {
		'User.UserName': '@[Error.Required]',
		'User.PersonName': '@[Error.Required]'
	},
	commands: {
		create
	}
}

export default template;

async function create(user) {
	const ctrl: IController = this.$ctrl;
	let newuser = await ctrl.$invoke("createUser", { User: user });
	console.dir(newuser);
	ctrl.$modalClose(newuser);
}