
export interface TUnit extends IElement {
	readonly Id: number;
	Short: string;
}

export interface TItemRole extends IElement {
	readonly Id: number;
}

export interface TRow extends IArrayElement {
	Qty: number;
	Price: number;
	Sum: number;
	ESum: number;
	Unit: TUnit;
	ItemRole: TItemRole;
}

declare type TRows = IElementArray<TRow>

export interface TDocExtra extends IElement {
	WriteSupplierPrices: boolean;
	IncludeServiceInCost: boolean;
}

export interface TDocument extends IElement {
	StockRows: TRows;
	ServiceRows: TRows;
	Extra: TDocExtra;
	// computed
	$StockSum: number;
	$StockESum: number;
	$ServiceSum: number;
}

export interface TRoot extends IRoot {
	Document: TDocument;
}
