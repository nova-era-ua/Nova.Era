// unit.template

const template: Template = {
	properties: {
		'TUnit.$Id'() { return this.Id ? this.Id : '@[NewItem]' }
	},
	validators: {
		'Unit.Short': '@[Error.Required]',
		'Unit.Name': '@[Error.Required]',
		'Unit.CodeUA': { valid: validCode, msg: '@[Error.UnitCodeUA]' }
	}
};

export default template;

function validCode(unit) {
	return !unit.CodeUA || unit.CodeUA.length === 4;
}
