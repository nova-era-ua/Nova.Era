
// print.browse

const template: Template = {
	properties: {
		'TPrintForm.$ReportUrl': reportUrl
	},
	commands: {
		testAtt
	}
};

function reportUrl(): string {
	return `/report/show/${this.DocumentId}?base=${this.Url}&rep=${this.Report}`;
}

export default template;

async function testAtt() {
	let ctrl: IController = this.$ctrl;
	//let res = await ctrl.$invoke('attachReport', { Report: 'document/print/waybillout.printform', Id: this.PrintForms.$selected.DocumentId, TenantId:1 });
	let res = await ctrl.$invoke('attachReport', { Base: 'document/print', Report:'waybillout' , Id: this.PrintForms.$selected.DocumentId });
	alert(JSON.stringify(res));
}