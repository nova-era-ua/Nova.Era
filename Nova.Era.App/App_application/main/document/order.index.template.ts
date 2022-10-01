
// order.index

declare const d3: any;

const base: Template = require("document/_common/index.module");
const bind: any = require("document/_common/bind.module");
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name; },
		'TDocument.$PaymentHtml': bind.bindSum("Payment"),
		'TDocument.$ShipmentHtml': bind.bindSum("Shipment") 
	},
	events: {
		'app.document.link': handleLink
	}
};

export default utils.mergeTemplate(base, template);

function handleLink(elem) {
	let doc = this.Documents.find(doc => doc.Id === elem.Id);
	if (!doc) return;
	console.dir(elem.LinkedDocs);
	doc.LinkedDocs.$copy(elem.LinkedDocs);
}
