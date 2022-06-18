
export interface TAccount extends ITreeElement {
	Id: number;
	Code: string;
	Name: string;
	Plan: number;
	IsFolder: boolean;
	$IsPlan: Boolean
}

export interface TParam {
	ParentAccount: number;
}

export interface TRoot extends IRoot {
	Account: TAccount;
	Params: TParam;
}
