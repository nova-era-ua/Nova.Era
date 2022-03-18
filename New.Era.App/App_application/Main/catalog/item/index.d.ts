
export interface TFolder extends ITreeElement {
	Id: number;
	Name: string;
	Icon: string;
	readonly SubItems: TFolders;
	HasSubItems: boolean;

	readonly $root: TRoot;
	readonly $IsFolder: boolean;
	readonly $IsSearch: boolean;

	readonly $parent: TFolders;
}

export interface THierarchy extends IElement {
	readonly Id: number;
	readonly Name: string;
}

declare type TFolders = IElementArray<TFolder>;

export interface TRoot extends IRoot {
	readonly Folders: TFolders;
	readonly Hierarchy: THierarchy;
	$Filter: string;
}

