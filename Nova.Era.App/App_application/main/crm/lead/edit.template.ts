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

async function tagSettings() {
	const ctrl: IController = this.$ctrl;
	let tags = await ctrl.$showDialog('/catalog/tag/settings', null, { For: 'Lead' });
	this.Tags.$copy(tags);
	this.Lead.Tags.forEach(lt => {
		let nt = tags.find(t => t.Id == lt.Id);
		if (nt) lt.$merge(nt);
	});
}
