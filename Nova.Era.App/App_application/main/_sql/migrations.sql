-- MIGRATIONS
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'acc' and TABLE_NAME = N'Accounts' and COLUMN_NAME=N'IsRespCenter')
begin
	alter table acc.Accounts add IsRespCenter bit;
	alter table acc.Accounts add IsCostItem bit;
end
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Documents' and COLUMN_NAME=N'Temp')
	alter table doc.Documents add Temp bit not null constraint DF_Documents_Temp default(0) with values;
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Documents' and COLUMN_NAME=N'ItemRole')
begin
	alter table doc.Documents add ItemRole bigint null;
	alter table doc.Documents add constraint FK_Documents_ItemRole_ItemRoles foreign key (TenantId, ItemRole) references cat.ItemRoles(TenantId, Id);
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
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'DocDetails' and COLUMN_NAME=N'ItemRoleTo')
begin
	alter table doc.DocDetails add ItemRoleTo bigint null;
	alter table doc.DocDetails add constraint FK_DocDetails_ItemRoleTo_ItemRoles foreign key (TenantId, ItemRoleTo) references cat.ItemRoles(TenantId, Id);
end
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'DocDetails' and COLUMN_NAME=N'ESum')
begin
	alter table doc.DocDetails add [ESum] money not null -- extra sum
		constraint DF_DocDetails_ESum default(0);
	alter table doc.DocDetails add [DSum] money null -- discount sum
		constraint DF_DocDetails_DSum default(0);
	alter table doc.DocDetails add [TSum] money null -- total sum
		constraint DF_DocDetails_TSum default(0);
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
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'ItemRoles' and COLUMN_NAME=N'Kind')
begin
	alter table cat.ItemRoles add [Kind] nvarchar(16); -- may be null for migrations
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
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Documents' and COLUMN_NAME=N'SNo')
	alter table doc.Documents add [SNo] nvarchar(64);
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Documents' and COLUMN_NAME=N'OpLink')
begin
	alter table doc.Documents add OpLink bigint;
	alter table doc.Documents add 
		constraint FK_Documents_OpLink_Documents foreign key (TenantId, OpLink) references doc.OperationLinks(TenantId, Id);
end
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Contracts' and COLUMN_NAME=N'Kind')
begin
	alter table doc.Contracts add Kind nvarchar(16);
	alter table doc.Contracts add constraint FK_Contracts_Kind_ContractKinds foreign key (TenantId, Kind) references doc.ContractKinds(TenantId, Id);
end
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Items' and COLUMN_NAME=N'Barcode')
begin
	alter table cat.Items add Barcode nvarchar(32);
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Operations' and COLUMN_NAME=N'WriteSupplierPrices')
	alter table doc.Operations drop column [WriteSupplierPrices];
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where TABLE_SCHEMA=N'cat' and TABLE_NAME = N'Items' and CONSTRAINT_NAME = N'FK_Items_Brand_Brands')
	alter table cat.Items add constraint FK_Items_Brand_Brands foreign key (TenantId, Brand) references cat.Brands(TenantId, Id);
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Forms' and COLUMN_NAME=N'Category')
	alter table doc.Forms add Category nvarchar(255);
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Agents' and COLUMN_NAME=N'Partner')
begin
	alter table cat.Agents add [Partner] bit;
	alter table cat.Agents add [Person] bit;
	-- roles
	alter table cat.Agents add IsSupplier bit;
	alter table cat.Agents add IsCustomer bit;
end
go
------------------------------------------------
if not exists(select * from cat.Agents where [Partner] is not null)
	update cat.Agents set [Partner] = 1 where [Partner] is null;
go
------------------------------------------------
if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Warehouses' and COLUMN_NAME=N'RespPerson')
	alter table  cat.Warehouses add RespPerson bigint,
		constraint FK_Warehouses_RespPerson_Agents foreign key (TenantId, RespPerson) references cat.Agents(TenantId, Id);
go
------------------------------------------------
drop table if exists doc.DocumentApply
drop procedure if exists doc.[Document.Stock.Update];
drop type if exists doc.[Document.Apply.TableType];
drop procedure if exists cat.[Item.Browse.Rems.Index];
drop procedure if exists cat.[Item.Find.Article];
go
update cat.ItemRoles set Kind = N'Item' where Kind is null;
go
