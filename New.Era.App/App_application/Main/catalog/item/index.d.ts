export interface TParentFolder extends IArrayElement {
	readonly Id: number;
}

export interface TItem extends IArrayElement {
	readonly Id: number;
	readonly ParentFolder: TParentFolder;
}

declare type TItems = IElementArray<TItem>;

export interface TFolder extends ITreeElement {
	Id: number;
	Name: string;
	Icon: string;
	readonly SubItems: TFolders;
	HasSubItems: boolean;
	Children: TItems;

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

