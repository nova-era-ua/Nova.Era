
const cu: UtilsCurrency = require('std:utils').currency;

const template: Template = {
	properties: {
		'TDocument.$Bind': docBind
	}
};

export default template;

function docBind() {
	let shipSum = this.LinkedDocs.reduce((p, c) => p + (c.BindKind === 'Shipment' ? c.Sum * c.BindFactor : 0), 0);
	let paySum = this.LinkedDocs.reduce((p, c) => p + (c.BindKind === 'Payment' ? c.Sum * c.BindFactor : 0), 0);
	let ship = Math.round(shipSum * 100.0 / this.Sum);
	let paymnt = Math.round(paySum * 100.0 / this.Sum);
	let payColor = '#9affac';
	let shipColor = "#cabeff";
	return `
<div class="bind-doc">
	<div class="bind-item" style="--pct:${ship}%; --color:${shipColor};">
		<i class="ico ico-truck"></i>
		<div>${cu.format(shipSum)}</div>
		<div class="bind-chart">${ship} %</div>
	</div>
	<div class="bind-item" style="--pct:${paymnt}%; --color:${payColor};">
		<i class="ico ico-currency-uah"></i>
		<div>${cu.format(paySum)}</div>
		<div class="bind-chart">${paymnt} %</div>
	</div>
</div>
`;
}
