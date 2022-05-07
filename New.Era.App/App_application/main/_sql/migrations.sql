-- MIGRATIONS
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'acc' and TABLE_NAME = N'Accounts' and COLUMN_NAME=N'IsRespCenter')
begin
	alter table acc.Accounts add IsRespCenter bit;
	alter table acc.Accounts add IsCostItem bit;
end
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'DocDetails' and COLUMN_NAME=N'CostItem')
begin
	alter table doc.DocDetails add CostItem bigint;
	alter table doc.DocDetails add constraint FK_DocDetails_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id);
end
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'ItemRoles' and COLUMN_NAME=N'CostItem')
begin
	alter table cat.ItemRoles add CostItem bigint;
	alter table cat.ItemRoles add constraint FK_ItemRoles_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id);
end
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Documents' and COLUMN_NAME=N'Parent')
begin
	alter table doc.Documents add [Parent] bigint;
	alter table doc.Documents add [Base] bigint;
	alter table doc.Documents add 
		constraint FK_Documents_Base_Documents foreign key (TenantId, [Base]) references doc.Documents(TenantId, Id);
	alter table doc.Documents add 
		constraint FK_Documents_Parent_Documents foreign key (TenantId, [Parent]) references doc.Documents(TenantId, Id);
end
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Documents' and COLUMN_NAME=N'OpLink')
begin
	alter table doc.Documents add OpLink bigint;
	alter table doc.Documents add 
		constraint FK_Documents_OpLink_Documents foreign key (TenantId, OpLink) references doc.OperationLinks(TenantId, Id);
end
go