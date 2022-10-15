// contact.edit.template

const dateUtils: UtilsDate = require("std:utils").date;

const template: Template = {
	properties: {
		'TContact.$Id'() { return this.Id ? this.Id : '@[NewItem]' },
		'TContact.$AddressUrl'() { return `https://www.google.com/maps/place/${this.Address}`; },
		'TContact.$HasAddress'() { return !!this.Address; },
		'TContact.$HasEmail'() { return !!this.Email },
	},
	validators: {
		'Contact.Name': '@[Error.Required]',
		'Contact.Email': { valid: StdValidator.email, msg: '@[Error.Email]' }
	},
	defaults: {
	}
};

export default template;
