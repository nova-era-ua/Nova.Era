
const template: Template = {
	properties: {
		'TAccount.$Name'() { return `${this.Code} ${this.Name}`;},
		'TRepData.$DtStart': total('DtStart'),
		'TRepData.$CtStart': total('CtStart'),
		'TRepData.$DtEnd': total('DtEnd'),
		'TRepData.$CtEnd': total('CtEnd')
	}
};

export default template;

function total(prop) {
	return function () {
		return this.Items.reduce((p, c) => p + c[prop], 0);
	};
}

function dtTotals() {
	return this.$cross.DtCross.map(x => {
		return {
			Sum: this.reduce((prev, curr) =>
				prev + curr.DtCross.find(ci => ci.Acc === x).Sum, 0)
		};
	});
}

function ctTotals() {
	return this.$cross.CtCross.map(x => {
		return {
			Sum: this.reduce((prev, curr) =>
				prev + curr.CtCross.find(ci => ci.Acc === x).Sum, 0)
		};
	});
}
