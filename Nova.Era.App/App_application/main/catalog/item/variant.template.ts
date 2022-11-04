

const template: Template = {
	properties: {
		'TRoot.$Options2': options2,
		'TRoot.$Opt2Disabled'() { return !this.Item.Option1.Id; },
		'TItem.Variants': variants
	},
	defaults: {
	},
	validators: {
	},
	commands: {
	}
};

export default template;

function options2() {
	let id1 = this.Item.Option1.Id;
	if (!id1)
		return [];
	return this.Options.filter(x => x.Id !== id1);
}

function variants() {
	let arr = [];
	this.Option1.Values.forEach(v1 => {
		if (this.Option2.Id)
			this.Option2.Values.forEach(v2 => {
				arr.push({ Checked: true, Id1: v1.Id, Name1: v1.Name, Id2: v2.Id, Name2: v2.Name });
			})
		else
			arr.push({ Checked: true, Id1: v1.Id, Name1: v1.Name, Id2: 0, Name2: null });
	});
	return arr;
}