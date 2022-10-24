
const template: Template = {
	properties: {
		'TIntegration.$Image': image
	},
	validators: {
		'Integration.Name': '@[Error.Required]',
		'Integration.ApiKey': '@[Error.Required]',
	},
	commands: {
		deleteMe,
	}
};

export default template;


function image() {
	return `<img src="${this.Logo}" width="50px">`;
}

async function deleteMe() {
	let ctrl: IController = this.$ctrl;
	await ctrl.$invoke('delete', { Id: this.Integration.Id }, '/settings/integration');
	ctrl.$modalClose();
	ctrl.$emitCaller('app.element.delete', this);
}
