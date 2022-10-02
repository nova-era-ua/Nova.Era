
// browse base document

const bind = require("document/_common/bind.module");

const template: Template = {
	properties: {
		'TDocument.$PaymentHtml': bind.bindSum("Payment"),
		'TDocument.$ShipmentHtml': bind.bindSum("Shipment") 
	}
};

export default template;

