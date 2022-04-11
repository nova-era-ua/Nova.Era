
const template: Template = {
	properties: {
		'TReport.$Url'() { return this.Url + "/" + this.Id;} 
	}
}

export default template;