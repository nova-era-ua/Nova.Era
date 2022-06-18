
export interface TParentFolder extends IArrayElement {
	readonly Id: number;
}

export interface TTreeItem extends IArrayElement {
	readonly Id: number;
	readonly ParentFolder: TParentFolder;
}

export interface TFolder<T> extends ITreeElement {
	Id: number;
	Name: string;
	Icon: string;
	HasSubItems: boolean;
	readonly Children: IElementArray<T>

	readonly $IsFolder: boolean;
	readonly $IsSearch: boolean;

	readonly $root: TRoot<T>;
}

export interface THierarchy extends IElement {
	readonly Id: number;
	readonly Name: string;
}

export interface TRoot<T> extends IRoot {
	readonly Hierarchy: THierarchy;
	$Filter: string;
}