
export interface TMenu extends IElement {
	readonly Id: string;
	readonly FormId: string;
}

export interface TOperation extends IArrayElement {
	readonly Id: number;
	Documents: TDocuments;
}

declare type TOperations = IElementArray<TOperation>;

export interface TDocument extends IArrayElement {
	readonly Id: number;
	Date: Date;
	Done: boolean;
	Operation: TOperation;
}
declare type TDocuments = IElementArray<TDocument>;


export interface TRoot extends IRoot {
	readonly Documents: TDocuments;
}