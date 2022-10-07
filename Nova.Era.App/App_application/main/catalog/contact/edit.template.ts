// contact.edit.template

const dateUtils: UtilsDate = require("std:utils").date;

const template: Template = {
	properties: {
		'TContact.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Contact.Name': '@[Error.Required]',
	},
	defaults: {
	}
};

export default template;
