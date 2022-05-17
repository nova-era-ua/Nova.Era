
const du: UtilsDate = require('std:utils').date;

const template: Template = {
	properties: {
		'TAccount.$Name'() { return `${this.Code} ${this.Name}`; },
		'TContract.$Name'() { return !this.Id ? '' : (this.Name ?? `№ ${this.SNo} від ${du.formatDate(this.Date)}`); },
		'TRepData.$Name'() { return this.$level === 1 ? this.Agent.Name : (this.Contract.$Name || '@[NoContract]'); },
		'TRepDataArray.$DtColSpan'() { return this.$cross.DtCross.length + 1; },
		'TRepDataArray.$CtColSpan'() { return this.$cross.CtCross.length + 1; }
	},
	events: {
		'Model.load': modelLoad
	}
};

export default template;

function calcCrossTotals(elem) {
	elem.Items.forEach(itemOut => {
		calcCrossTotals(itemOut);
		itemOut.Items.forEach(itemIn => {
			itemOut.CtCross.forEach((e, i) => e.Sum += itemIn.CtCross[i].Sum);
			itemOut.DtCross.forEach((e, i) => e.Sum += itemIn.DtCross[i].Sum);
		});
	});
}

function modelLoad() {
	calcCrossTotals(this.RepData);
	// and root too
	this.RepData.Items.forEach(item => {
		this.RepData.CtCross.forEach((e, i) => e.Sum += item.CtCross[i].Sum);
		this.RepData.DtCross.forEach((e, i) => e.Sum += item.DtCross[i].Sum);
	});
	// unflod total saldo
	var calcSaldo = (v) => {
		this.RepData[v] = this.RepData.Items.reduce((p, c) => p + c[v], 0);
	}
	calcSaldo('DtStart');
	calcSaldo('CtStart');
	calcSaldo('DtEnd');
	calcSaldo('CtEnd');
}

