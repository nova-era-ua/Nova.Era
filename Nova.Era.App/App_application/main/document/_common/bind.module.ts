
const cu: UtilsCurrency = require('std:utils').currency;

const module = {
	bindSum
};

export default module;

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

function bindSum(prop) {
	return function () {
		let sum = this.LinkedDocs.reduce((p, c) => p + (c.BindKind === prop ? c.Sum * c.BindFactor : 0), 0);
		if (!sum)
			return '';
		let pct = Math.min(Math.round(sum * 100.0 / this.Sum), 100);
		let color = pct < 100 ? '#c60000' : '#00c663'
		let colorBack = pct < 100 ? '#c6000010' : '#00c66310';
		let sumStr = cu.format(sum);
		return `
		<div class="bind-sum" style="--pct:${pct}%; --clr-brd:${color}; --clr-bk:${colorBack}">
			<div>${sumStr}</div>
		</div>
	`;
	}
}