
import { TRoot, TFolder, TFolders} from 'index.d';

const template: Template = {
	properties: {
		'TRoot.$Filter': String,
		'TFolder.$IsSearch'(this: TFolder): boolean { return this.Id === -1; },
		'TFolder.$IsFolder'(this: TFolder): boolean { return this.Id !== -1; },
		'TFolder.$IsVisible'(this: TFolder): boolean {
			return this.$IsFolder || !!this.$root.$Filter;
		}
	}
}

export default template;