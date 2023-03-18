/*
version: 10.1.1040
generated: 18.03.2023 12:48:41
*/


/* SqlScripts/personnel.sql */

/*
PERSONNEL user interface
12000, 120
*/
------------------------------------------------
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @menu ui.[MenuModule.TableType];

	insert into @menu(Id, Parent, [Order], [Name], [Url], Icon, ClassName) 
	values

		(12000,     1, 120,  N'@[Manufacturing]', N'personnel',  N'user-image', null),
		-- Manufacturing
		(12001, 12000,  10, N'@[Dashboard]',      N'dashboard', N'dashboard-outline', N'border-bottom'),
		(12002, 12000,  11, N'@[Documents]',      null,  null, null),
		(12003, 12000,  12, N'@[Catalogs]',       null,  null, null),
		(12004, 12000,  40, N'@[Reports]',        N'report',    N'report', N'border-top');
		-- documents
		-- catalogs

	exec ui.[MenuModule.Merge] @menu, 12000, 12999;
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

