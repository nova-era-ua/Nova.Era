-- MIGRATIONS
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Countries' and COLUMN_NAME=N'Alpha3')
	alter table cat.Countries add [Alpha3] nchar(3);
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Countries' and COLUMN_NAME=N'Aplha3')
	alter table cat.Countries drop column [Aplha3];
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items' and COLUMN_NAME=N'Country')
	alter table cat.Items add Country nchar(3); -- references cat.Countries
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Items' and CONSTRAINT_NAME = N'FK_Items_Country_Countries')
	alter table cat.Items add 
		constraint FK_Items_Country_Countries foreign key (TenantId, Country) references cat.Countries(TenantId, Code);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Companies' and COLUMN_NAME=N'AutonumPrefix')
	alter table cat.Companies add [AutonumPrefix] nvarchar(8);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations' and COLUMN_NAME=N'Autonum')
	alter table doc.Operations add Autonum bigint; -- references doc.Autonums
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Operations' and CONSTRAINT_NAME = N'FK_Operations_Autonum_Autonums')
	alter table doc.Operations add 
		constraint FK_Operations_Autonum_Autonums foreign key (TenantId, Autonum) references doc.Autonums(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'No')
	alter table doc.Documents add [No] nvarchar(64);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Autonums' and COLUMN_NAME=N'Uid')
	alter table doc.Autonums add [Uid] uniqueidentifier not null
		constraint DF_Autonum_Uid default(newid()) with values;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal' and COLUMN_NAME=N'CostItem')
begin
	alter table jrn.StockJournal add CostItem bigint;
	alter table jrn.StockJournal add RespCenter bigint;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_SCHEMA = N'jrn' and TABLE_NAME = N'StockJournal' and CONSTRAINT_NAME = N'FK_StockJournal_CostItem_CostItems')
begin
	alter table jrn.StockJournal add constraint FK_StockJournal_CostItem_CostItems foreign key (TenantId, CostItem) references cat.CostItems(TenantId, Id);
	alter table jrn.StockJournal add constraint FK_StockJournal_RespCenter_RespCenters foreign key (TenantId, RespCenter) references cat.RespCenters(TenantId, Id);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal' and COLUMN_NAME=N'Agent')
begin
	alter table jrn.StockJournal add Agent bigint null;
	alter table jrn.StockJournal add [Contract] bigint null;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_SCHEMA = N'jrn' and TABLE_NAME = N'StockJournal' and CONSTRAINT_NAME = N'FK_StockJournal_Agent_Agents')
begin
	alter table jrn.StockJournal add constraint 
		FK_StockJournal_Agent_Agents foreign key (TenantId, Agent) references cat.Agents(TenantId, Id);
	alter table jrn.StockJournal add constraint 
		FK_StockJournal_Contract_Contracts foreign key (TenantId, [Contract]) references doc.Contracts(TenantId, Id);
end
go

------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Companies' and COLUMN_NAME=N'Logo')
	alter table cat.Companies add Logo bigint null
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Companies' and CONSTRAINT_NAME = N'FK_Companies_Logo_Blobs')
	alter table cat.Companies add constraint 
		FK_Companies_Logo_Blobs foreign key (TenantId, Logo) references app.Blobs(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OpTrans' and COLUMN_NAME=N'Factor')
	alter table doc.OpTrans add Factor smallint -- 1 normal, -1 storno
		constraint CK_OpTrans_Factor check (Factor in (1, -1))
		constraint DF_OpTrans_Factor default (1) with values;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'Journal' and COLUMN_NAME=N'Project')
	alter table jrn.Journal	add Project bigint null,
		constraint FK_Journal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'Journal' and COLUMN_NAME=N'Operation')
	alter table jrn.Journal	add Operation bigint null,
		constraint FK_Journal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'Project')
	alter table doc.Documents add Project bigint null,
		constraint FK_Documents_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal' and COLUMN_NAME=N'Project')
	alter table jrn.StockJournal add Project bigint,
		constraint FK_StockJournal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'CashJournal' and COLUMN_NAME=N'Project')
	alter table jrn.CashJournal add Project bigint,
		constraint FK_CashJournal_Project_Projects foreign key (TenantId, Project) references cat.Projects(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'StockJournal' and COLUMN_NAME=N'Operation')
	alter table jrn.StockJournal add Operation bigint,
		constraint FK_StockJournal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'jrn' and TABLE_NAME=N'CashJournal' and COLUMN_NAME=N'Operation')
	alter table jrn.CashJournal add Operation bigint,
		constraint FK_CashJournal_Operation_Operations foreign key (TenantId, Operation) references doc.Operations(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations' and COLUMN_NAME=N'Kind')
	alter table doc.Operations add [Kind] nvarchar(16),
		constraint FK_Operations_Kind_OperationKinds foreign key (TenantId, Kind) references doc.OperationKinds(TenantId, Id);
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations' and COLUMN_NAME=N'Agent')
begin
	alter table doc.Operations drop column Agent;
	alter table doc.Operations drop column WarehouseFrom;
	alter table doc.Operations drop column WarehouseTo;
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'OperationKinds' and COLUMN_NAME=N'LinkType')
	alter table doc.OperationKinds add LinkType nchar(1);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'BindKind')
begin
	alter table doc.Documents add BindKind nvarchar(16);
	alter table doc.Documents add BindFactor smallint;
end
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'ReconcileFactor')
begin
	alter table doc.Documents drop column ReconcileFactor;
	alter table doc.Documents drop column [Reconcile];
end
go
------------------------------------------------
drop table if exists jrn.Reconcile;
drop sequence if exists jrn.SQ_Reconcile;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'crm' and TABLE_NAME=N'LeadStages' and COLUMN_NAME=N'Memo')
	alter table crm.LeadStages add [Memo] nvarchar(255);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'crm' and TABLE_NAME=N'LeadStages' and COLUMN_NAME=N'Kind')
	alter table crm.LeadStages add [Kind] nchar(1);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Contacts' and COLUMN_NAME=N'Email')
begin
	alter table cat.Contacts add Email nvarchar(64);
	alter table cat.Contacts add Phone nvarchar(32);
	alter table cat.Contacts add [Address] nvarchar(255);
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Forms' and COLUMN_NAME=N'HasState')
	alter table doc.Forms add HasState bit;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Documents' and COLUMN_NAME=N'State')
	alter table doc.Documents add [State] bigint,
		constraint FK_Documents_State_DocStates foreign key (TenantId, [State]) references doc.DocStates(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items' and COLUMN_NAME=N'Parent')
	alter table cat.Items add Parent bigint,
		constraint FK_Items_Parent_Items foreign key (TenantId, [Parent]) references cat.Items(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items' and COLUMN_NAME=N'Variant')
	alter table cat.Items add Variant bigint,
		constraint FK_Items_Variant_ItemVariants foreign key (TenantId, Variant) references cat.ItemVariants(TenantId, Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Items' and COLUMN_NAME=N'IsVariant')
	alter table cat.Items add IsVariant as (cast(case when [Parent] is not null then 1 else 0 end as bit));
go


