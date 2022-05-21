

export interface TPriceValue extends IArrayElement {
	PriceKind: number;
	Price: number;
}

declare type TPriceValues = IElementArray<TPriceValue>;

export interface TPriceItem extends IElement {
	readonly Id: number;
	Values: TPriceValues;
	readonly $root: TRoot;

}

export interface TPriceKind extends IArrayElement {
	readonly Id: number;
}

export interface TChecked extends IElement {
	PriceKind1: TPriceKind;
	PriceKind2: TPriceKind;
	PriceKind3: TPriceKind;
}


export interface TRoot extends IRoot {
	Checked: TChecked;
}



