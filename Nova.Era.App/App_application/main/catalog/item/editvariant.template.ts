
const barcode = require('std:barcode');

const template: Template = {
	commands: {
		generateBarcode
	}
};

export default template;

async function generateBarcode(item) {
	item.Barcode = barcode.generateEAN13('20', item.Id);
}
