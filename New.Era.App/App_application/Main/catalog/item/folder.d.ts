
export interface TFolder extends ITreeElement {
	Id: number;
	Name: string;
	ParentFolder: number;
}

export interface TParentFolder extends ITreeElement {
	Id: number;
	Name: string;
}

export interface TRoot extends IRoot {
	readonly Folder: TFolder;
	readonly ParentFolder: TParentFolder;
}

