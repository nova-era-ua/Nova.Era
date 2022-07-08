

const template: Template = {
	properties: {
		'TItemRole.$Kind': itemRoleKind
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