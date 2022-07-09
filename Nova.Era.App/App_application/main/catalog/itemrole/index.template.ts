

const template: Template = {
	properties: {
		'TItemRole.$Kind': itemRoleKind,
		'TItemRole.$ExType': exType
	},
};

export default template;


function itemRoleKind() {
	switch (this.Kind) {
		case 'Item': return "@[Item]";
		case 'Money': return "@[Money]";
		case 'Expense': return "@[Expense]";
		case 'Revenue': return "@[Revenue]";
	}
	return this.Kind;
}

function exType() {
	switch (this.ExType) {
		case 'C': return "@[CashFunds]";
		case 'B': return "@[NonCashFunds]";
	}
	return '';
}