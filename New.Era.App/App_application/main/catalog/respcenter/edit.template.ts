// respcenter.template

const template: Template = {
	properties: {
		'TRespCenter.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'RespCenter.Name': '@[Error.Required]',
	}
};

export default template;
