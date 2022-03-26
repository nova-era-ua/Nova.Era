
export interface TForm extends IElement {
	readonly Id: string;
	readonly Name: string;
}

export interface TOperation extends IArrayElement {
	readonly Id: number;
	Form: TForm;
	Documents: TDocuments;
}

declare type TOperations = IElementArray<TOperation>;

export interface TDocument extends IArrayElement {
	readonly Id: number;
	Date: Date,
	Operation: TOperation;
}
declare type TDocuments = IElementArray<TDocument>;


export interface TRoot extends IRoot {
	readonly Documents: TDocuments;
}