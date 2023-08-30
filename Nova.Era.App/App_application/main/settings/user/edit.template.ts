
// User.Edit
const template: Template = {
	validators: {
		'User.UserName': '@[Error.Required]',
		'User.PersonName': '@[Error.Required]'
	},
}

export default template;
