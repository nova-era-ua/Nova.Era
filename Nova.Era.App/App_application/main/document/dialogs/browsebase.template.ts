﻿
// browse base document

const utils: Utils = require('std:utils');

const template: Template = {
	properties: {
		'TDocument.$Bind': docBind
	}	
};

export default template;


function docBind() {

	let ship = Math.round(this.Bind.Shipment * 100.0 / this.Sum);
	let paymnt = Math.round(this.Bind.Payment * 100.0 / this.Sum);
	let payColor = '#9affac';
	let shipColor = "#cabeff";
	return `
<div class="bind-doc">
	<div class="bind-item" style="--pct:${ship}%; --color:${shipColor};">
		<i class="ico ico-truck"></i>
		<div class="bind-chart">${ship} %</div>
	</div>
	<div class="bind-item" style="--pct:${paymnt}%; --color:${payColor};">
		<i class="ico ico-currency-uah"></i>
		<div class="bind-chart">${paymnt} %</div>
	</div>
</div>
`;
}