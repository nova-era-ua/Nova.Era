﻿

const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TItemRole.$Id'() { return this.Id || '@[NewItem]' },
		'TRoleAccount.$PlanArg'() { return { Plan: this.Plan.Id }; },
		'TItemRole.$HasStock'() { return this.Kind === 'Item'; },
		'TItemRole.$HasMoneyType'() { return this.Kind === 'Money'; },
		'TItemRole.$HasCostItem'() { return this.Kind !== 'Money'; }
	},
	defaults: {
		'ItemRole.Kind': 'Item'
	},
	validators: {
		'ItemRole.Name': '@[Error.Required]',
		'ItemRole.Accounts[].Plan': '@[Error.Required]',
		'ItemRole.Accounts[].AccKind': '@[Error.Required]',
		'ItemRole.Accounts[].Account': '@[Error.Required]'
	},
	events: {
		'ItemRole.Kind.change': kindChange
	}
};

export default template;

function kindChange(role, kind) {
	if (kind === 'Money') {
		if (!role.ExType)
			role.ExType = 'C';
	} else {
		role.ExType = '';
	}
}