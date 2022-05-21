
import { TPriceItem, TRoot } from "index";

const template: Template = {
	properties: {
		'TRoot.$Disabled1': getDisabled(1),
		'TRoot.$Disabled2': getDisabled(2),
		'TRoot.$Disabled3': getDisabled(3),
		'TPriceItem.$Price1': getPriceProp(1),
		'TPriceItem.$Price2': getPriceProp(2),
		'TPriceItem.$Price3': getPriceProp(3)
	},
	commands: {
	},
	events: {
	}
};

export default template;


function getDisabled(no) {
	return function () {
		let pk = this.Checked[`PriceKind${no}`];
		return pk.Id ? false : true;
	}
}

function getPriceProp(no) {
	return {
		get(this: TPriceItem) {
			let pk = this.$root.Checked[`PriceKind${no}`];
			if (!pk || !pk.Id) return 0;
			let val = this.Values.find(v => v.PriceKind == pk.Id);
			return val ? val.Price : 0;
		},
		async set(this: TPriceItem, val: number) {
			let pk = this.$root.Checked[`PriceKind${no}`];
			if (!pk) return;
			let date = (this.$parent as any).$ModelInfo?.Filter?.Date;
			if (!date) return;
			let pval = this.Values.find(v => v.PriceKind == pk.Id);
			if (pval)
				pval.Price = val;
			else
				this.Values.$append({ PriceKind: pk.Id, Date: date, Price: val })
			await this.$ctrl.$invoke('setPrice', { Id: this.Id, PriceKind: pk.Id, Date: date, Value: val });
		}
	}
}