import { TAccount, TRoot } from './edit';

const URLS = {
	editPlan: '/settings/accountplan/editPlan',
	edit: '/settings/accountplan/edit'
};

const template: Template = {
	properties: {
		'TAccount.$Title'(this: TAccount) { return `${this.Code} ${this.Name}`; },
		'TAccount.$Icon'() { return this.IsFolder ? 'account-folder' : 'account'; },
		'TAccount.$IsPlan'() { return this.Plan === 0; }
	},
	commands: {
		createPlan,
		createAccount: {
			exec: createAccount,
			canExec(parent: TAccount): boolean { return !!parent; }
		},
		edit: {
			exec: editAccount,
			canExec(item: TAccount): boolean { return !!parent; }
		}
	}
};

export default template;

async function createPlan(this: TRoot) {
	const ctrl = this.$ctrl;
	let plan = await ctrl.$showDialog(URLS.editPlan);
	let newplan = this.Accounts.$append(plan);
	newplan.$select(this.Accounts);
}

async function createAccount(this: TRoot, parent: TAccount) {
	if (!parent) return;
	const ctrl = this.$ctrl;
	await ctrl.$expand(parent, 'Items', true);
	let acc = await ctrl.$showDialog(URLS.edit, null, { Parent: parent.Id });
	let newacc = parent.Items.$append(acc);
	newacc.$select(this.Accounts);
}

function mergeProps(trg: TAccount, src: TAccount) {
	trg.Name = src.Name;
	trg.Code = src.Code;
	trg.IsFolder = src.IsFolder;
}

async function editAccount(this: TRoot, item: TAccount) {
	if (!item) return;
	const ctrl = this.$ctrl;
	if (item.$IsPlan) {
		let plan = await ctrl.$showDialog(URLS.editPlan, { Id: item.Id });
		mergeProps(item, plan);
	} else {
		let acc = await ctrl.$showDialog(URLS.edit, { Id: item.Id });
		mergeProps(item, acc);
	}
}