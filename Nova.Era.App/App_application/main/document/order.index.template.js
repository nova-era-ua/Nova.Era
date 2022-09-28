define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const base = require("document/_common/index.module");
    const utils = require("std:utils");
    const template = {
        properties: {
            'TDocument.$Warehouse'() { return this.WhFrom.Id ? this.WhFrom.Name : this.WhTo.Name; }
        },
        delegates: {
            drawShipment: createDraw("Shipment"),
            drawPayment: createDraw("Payment")
        }
    };
    exports.default = utils.mergeTemplate(base, template);
    function createDraw(type) {
        return function (g, doc) {
            let val = doc.Reconcile[type];
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
                .attr('width', '100px')
                .attr('viewBox', '0 0 100 22');
            line.append('rect')
                .attr('x', 0)
                .attr('y', 0)
                .attr('width', 100)
                .attr('height', 22)
                .attr('style', "fill:none;stroke:var(--neutralBkDarker);");
            if (!val)
                return;
            line.append('rect')
                .attr('x', 1)
                .attr('y', 1)
                .attr('width', scaleX(val) - 2)
                .attr('fill', scaleColor(val))
                .attr('height', 20);
            line.append('text')
                .attr('x', 95)
                .attr('y', 16)
                .attr('text-anchor', 'end')
                .attr('fill', '#000')
                .text(utils.currency.format(val));
        };
    }
});
