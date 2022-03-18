
import { TRoot, TFolder } from "./folder";


const template: Template = {
	properties: {
		'TFolder.$Title'(this: TFolder) { return this.Id ? this.Id : '@[NewFolder]' }
	},
	validators: {
		'Folder.Name': '@[Error.Required]'
	},
	defaults: {
		'Folder.ParentFolder'(this: TRoot) { return this.ParentFolder; }
	}
}

export default template;
