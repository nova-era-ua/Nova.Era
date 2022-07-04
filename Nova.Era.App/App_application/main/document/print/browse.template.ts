
// print.browse

const template: Template = {
	properties: {
		'TPrintForm.$ReportUrl': reportUrl
	}
};

function reportUrl(): string {
	return `/report/show/${this.DocumentId}?base=${this.Url}&rep=${this.Report}`;
}

export default template;