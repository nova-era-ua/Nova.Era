
import { TRoot } from "folder";
import { TFolder } from "./index";


const template: Template = {
	properties: {
		'TFolder.$Title'(this: TFolder) { return this.Id ? this.Id : '@[NewFolder]' }
	},
	validators: {
		'Folder.Name': StdValidator.notBlank
	},
	defaults: {
		'Folder.ParentFolder'(this: TRoot) { return this.ParentFolder.Id }
	}
}

export default template;
