
export interface TCurrency extends IElement {
	Id: number;
	NewId: number;
	Number3: string;
	Alpha3: string;
}

export interface TRoot extends IRoot {
	Currency: TCurrency
}