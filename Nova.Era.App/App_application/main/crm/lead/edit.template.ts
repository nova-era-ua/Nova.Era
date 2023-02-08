// contact.edit.template

const dateUtils: UtilsDate = require("std:utils").date;

const template: Template = {
	properties: {
		'TLead.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Lead.Name': '@[Error.Required]',
		'Lead.Stage': '@[Error.Required]'
	},
	defaults: {
		'Lead.Stage'(this: any) { return this.Stages.find(x => x.Kind === 'I'); }
	},
	delegates: {
		tagSettings
	}
};

export default template;

function tagSettings() {

}
