// order.index

declare const d3: any;

const base: Template = require("document/_common/index.module");
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name; }
	},
	delegates: {
		drawShipment: createDraw("Shipment"),
		drawPayment: createDraw("Payment")
	}
};

export default utils.mergeTemplate(base, template);

function createDraw(type) {
	return function (g, doc) {
		let val = doc.LinkSum[type].Sum;
		const scaleX = d3.scaleLinear()
			.range([0, 100])
			.domain([0, doc.Sum]);

		var scaleColor2 = d3.scaleSequential()
			.domain([0, doc.Sum])
			.interpolator(d3.interpolateRdYlGn);

		var scaleColor = d3.scaleLinear()
			.domain([0, doc.Sum])
			.interpolate(d3.interpolateHcl)
			.range([d3.rgb("#FFC1B7"), d3.rgb('#ACEB54')]);

		const line = g.append('svg')
			.attr('width', '80px')
			.attr('viewBox', '0 0 80 20');
		/*
		line.append('rect')
			.attr('x', -2)
			.attr('y', -4)
			.attr('width', 104)
			.attr('height', 28)
			.attr('fill', "#f8f8f8");
		*/

		if (!val)
			return;

		line.append('rect')
			.attr('x', 0)
			.attr('y', 0)
			.attr('width', scaleX(val))
			.attr('fill', scaleColor(val))
			.attr('height', 20);

		line.append('text')
			.attr('x', 78)
			.attr('y', 15)
			.attr('text-anchor', 'end')
			.attr('fill', '#000')
			.text(utils.currency.format(val));
	}
}