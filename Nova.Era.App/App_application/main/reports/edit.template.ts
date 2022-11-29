
const template: Template = {
	defaults: {
		'Report.Menu'(this: any) { return this.Params.Menu; },
		'Report.Type'(this: any) { return this.RepTypes[0]; }
	},
	properties: {
		'TAccount.$Title'() { return `${this.Code} ${this.Name}`; },
	},
	validators: {
		'Report.Name': '@[Error.Required]',
		'Report.Account': { valid: validAccount, msg: '@[Error.Required]' },
		'Report.File': '@[Error.Required]'
	}
}

export default template;


function validAccount(elem, val): boolean {
	console.dir(val);
	switch (elem.Type.Id) {
		case 'by.account': return !!elem.Account.Id;
	}
	return true;
}
