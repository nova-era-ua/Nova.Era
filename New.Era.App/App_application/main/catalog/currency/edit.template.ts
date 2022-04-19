
import { TCurrency, TRoot } from 'edit.d'

const template: Template = {
	properties: {
		'TCurrency.$Id'(this: TCurrency) { return this.Id || '@[NewItem]' },
		'TCurrency.NewId'(this: TCurrency) { return +this.Number3; }
	},
	defaults: {
		'Currency.Denom' : 1
	},
	validators: {
		'Currency.Number3': [
			'@[Error.Required]',
			{ valid: validLen, msg: '@[Error.Currency.Len]' },
			{ async: true, valid: checkDup, msg: '@[Error.Currency.DuplicateCode]' }
		],
		'Currency.Alpha3': ['@[Error.Required]', { valid: validLen, msg: '@[Error.Currency.Len]' }]
	}
};

export default template;

function validLen(elem: TCurrency, val: string) {
	return val.length === 3;
}

function checkDup(elem: TCurrency, val: string) {
	if (!val) return true;
	if (!validLen(elem, val)) return true;
	return elem.$ctrl.$asyncValid('checkDuplicate', { Id: elem.Id, Number3: val });
}