
export interface TAccount extends ITreeElement {
	Id: number;
	Code: string;
	Name: string;
	Plan: number;
	Items: TAccounts,
	IsFolder: boolean,
	$IsPlan: Boolean
}

declare type TAccounts = IElementArray<TAccount>;

export interface TRoot extends IRoot {
	Accounts: TAccounts;
}
