// task.edit
const template: Template = {
	properties: {
		'TTask.$Id'() {return this.Id ? this.Id : '@[NewItemW]' }
	},
	defaults: {
		'Task.LinkId'(this: any) { return this.Params.LinkId; },
		'Task.LinkType'(this: any) { return this.Params.LinkType; },
		'Task.LinkUrl'(this: any) { return this.Params.LinkUrl; },
		'Task.State'(this: any) { return this.States.length ? this.States[0] : null; }
	},
	validators: {
	}
};

export default template;