

const template: Template = {
	options: {
	},
	events: {
		'Model.load': modelLoad
	},
	commands: {
		addItem,
		editItem: {
			exec: editItem,
			canExec(this: any) { return !!this.Groups.$selected; }
		},
		addHierarchy
	}
};

export default template;

function modelLoad() {
	//if (this.Groups.length)
		//this.Groups[0].$expand();
}

async function addItem() {
	let parent = this.Groups.$selected;
	if (!parent) return;

	const ctrl: IController = this.$ctrl;

	await ctrl.$expand(parent, 'Items', true);

	let group = await ctrl.$showDialog('/catalog/itemgroup/edit', null, { Parent: parent.Id });
	let newgroup = parent.Items.$append(group);
	newgroup.$select(this.Groups);
}

async function editItem() {
	let elem = this.Groups.$selected;
	if (!elem) return;
	const ctrl: IController = this.$ctrl;
	let url = elem.IsRoot ? '/catalog/itemgroup/edithie' : '/catalog/itemgroup/edit';
	let group = await ctrl.$showDialog(url, { Id: elem.Id });
	elem.$merge(group);
}

async function addHierarchy() {
	const ctrl: IController = this.$ctrl;
	let group = await ctrl.$showDialog('/catalog/itemgroup/edithie', null);
	let newhie = this.Groups.$append(group);
	newhie.$select(this.Groups);
}