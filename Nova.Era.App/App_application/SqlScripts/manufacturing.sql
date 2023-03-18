/*
version: 10.1.1040
generated: 18.03.2023 12:48:41
*/


/* SqlScripts/manufacturing.sql */

/*
MANUFACTURING user interface
11000, 110
*/
------------------------------------------------
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @menu ui.[MenuModule.TableType];

	insert into @menu(Id, Parent, [Order], [Name], [Url], Icon, ClassName) 
	values

		(11000,     1, 110,  N'@[Manufacturing]', N'$manufacturing',  N'wrench', null),
		-- Manufacturing
		(11001, 11000,  10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(11002, 11000,  11, N'@[Documents]',      null,  null, null),
		(11003, 11000,  12, N'@[Catalogs]',       null,  null, null),
		(11004, 11000,  40, N'@[Reports]',        N'report',    N'report', N'border-top'),
		-- documents
		(11203, 11002,  10, N'@[Specifications]',  N'spec',      N'file', null),
		(11204, 11002,  20, N'@[Orders]',          N'order',     N'file', null),
		-- catalogs
		(11303, 11003,  10, N'@[Items]',          N'item',      N'package-outline', null),
		(11304, 11003,  20, N'@[Projects]',       N'project',   N'log', null),
		(11305, 11003,  30, N'@[CatalogOther]',   N'catalog',   N'list', null);

	exec ui.[MenuModule.Merge] @menu, 11000, 11999;
end
go

-------------------------------------------------
-- Catalog
begin
	set nocount on;
	declare @cat ui.[Catalog.TableType];

	insert into @cat (Id, Menu, [Order], [Category], [Name], [Url], Icon, Memo) values

	(11000, N'Manufacturing', 10, N'@[Items]', N'@[Units]',         N'/catalog/unit/index',       N'list',  N''),
	(11001, N'Manufacturing', 11, N'@[Items]', N'@[Grouping.Item]', N'/catalog/itemgroup/index',  N'list',  N'');

	-- settings
	exec ui.[Catalog.Merge] @cat, 11000, 11999;
end
go

