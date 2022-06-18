
export interface TItemRole extends ITreeElement {
	Id: number;
	Name: string;
}

declare type TItemRoles = IElementArray<TItemRole>;

export interface TItem extends IElement {
	Id: number;
	Name: string;
	Role: TItemRole;
}

export interface TRoot extends IRoot {
	readonly Item: TItem;
	readonly ItemRoles: TItemRoles;
}

