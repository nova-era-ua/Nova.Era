
drop table if exists usr.Defaults;
--
drop table if exists jrn.StockJournal;
drop table if exists jrn.Journal;
drop table if exists jrn.SupplierPrices;
drop table if exists doc.DocDetails;
drop table if exists doc.Documents;
drop table if exists doc.OpTrans;
drop table if exists doc.OpJournalStore;
drop table if exists cat.CashAccounts;
drop table if exists cat.CashFlowItems;
drop table if exists cat.CostItems;
drop table if exists cat.RespCenters;
drop table if exists doc.Contracts;
drop table if exists cat.PriceKinds;
drop table if exists cat.Currencies;
drop table if exists ui.OpMenuLinks;
drop table if exists doc.Operations;
drop table if exists rep.Reports;
drop table if exists rep.RepFiles;
drop table if exists rep.RepTypes;
drop table if exists doc.DocumentForms;
drop table if exists doc.OperationGroups;
drop table if exists doc.FormRowKinds;
drop table if exists doc.Forms;
drop table if exists doc.FormsMenu;
--
drop table if exists comp.Companies;
drop table if exists cat.Agents;
drop table if exists cat.ItemTreeElems;
drop table if exists cat.ItemTree;
drop table if exists cat.ItemRoleAccounts
drop table if exists cat.Items;
drop table if exists cat.ItemRoles;
drop table if exists cat.Banks;
drop table if exists cat.Companies;
drop table if exists cat.Warehouses;
drop table if exists cat.Vendors;
drop table if exists cat.Units;
drop table if exists acc.Accounts;
go

drop sequence if exists doc.SQ_OpTrans;
drop sequence if exists doc.SQ_Operations;
drop sequence if exists cat.SQ_Accounts;
drop sequence if exists acc.SQ_Accounts;
drop sequence if exists cat.SQ_BankAccounts;
go

drop function if exists cat.fn_GetBankAccountName;
go

/*
drop table if exists appsec.Users;
drop table if exists appsec.Tenants;
*/
go