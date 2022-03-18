
export interface TItem extends IElement {
	Id: number;
	Name: string;
	ParentFolder: number;
}

export interface TParentFolder extends ITreeElement {
	Id: number;
	Name: string;
}

export interface TRoot extends IRoot {
	readonly Item: TItem;
	readonly ParentFolder: TParentFolder;
}

