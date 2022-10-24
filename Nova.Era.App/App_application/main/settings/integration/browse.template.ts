
const template: Template = {
	properties: {
		'TRoot.$Name': String,
		'TRoot.$SelectedName'() { return this.Sources.$selected ? this.Sources.$selected.Name : ''; },
		'TSource.$Image': image,
		'TSource.$Category': category,
		'TSource.IntName'() { return this.$root.$Name || this.Name; }
	}
};

export default template;


function category() {
	switch (this.Key) {
		case 'Delivery': return '@[Int.Delivery]';
	}
	return this.Key;
}

function image() {
	return `<img src="${this.Logo}" height="40px">`;
}

