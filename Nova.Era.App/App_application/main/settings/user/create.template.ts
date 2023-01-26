
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

function create(user) {
	const ctrl: IController = this.$ctrl;
	ctrl.$invoke("createUser", { User: user });
	alert(JSON.stringify(user));
}