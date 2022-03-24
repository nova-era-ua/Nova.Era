/*
initial data
*/

------------------------------------------------
if not exists(select * from cat.Agents where Kind=N'Company')
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);

	insert into cat.Agents (TenantId, Kind, [Name]) 
	output inserted.Id into @rtable(id)
	values (1, N'Company', N'Моє підприємство');
end
go

-- ITEM TREE
if not exists(select * from cat.ItemTree where Id=0)
	insert into cat.ItemTree(TenantId, Id, Parent, [Root], [Name]) 
	values(1, 0, 0, 0, N'Root');
go
-------------------------------------------------
if not exists(select * from cat.ItemTree where Id=1)
	insert into cat.ItemTree(TenantId, Id, Parent, [Root], [Name]) 
	values(1, 1, 0, 0, N'(Default hierarchy)');
go
-------------------------------------------------
-- OPERATION GROUPS
begin
	set nocount on;
	declare @og table(Id nvarchar(16), [Order] int, [Name] nvarchar(255), Memo nvarchar(255));
	insert into @og (Id, [Order], [Name], [Memo]) values
		(N'Sales', 1, N'Продажі та маркетинг', N'Перелік операцій для продажів та маркетингу');
	merge doc.OperationGroups as t
	using @og as s on t.Id = s.Id and t.TenantId = 1
	when matched then update set
		t.[Name] = s.[Name],
		t.[Order] = s.[Order],
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		(TenantId, Id, [Order], [Name], [Memo]) values
		(1, s.Id, s.[Order], s.[Name], s.Memo)
	when not matched by source and t.TenantId = 1 then delete;
end
go
-------------------------------------------------
-- DOCUMENT FORMS
begin
	set nocount on;
	declare @df table(Id nvarchar(16), [Name] nvarchar(255), [Url] nvarchar(255));
	insert into @df (Id, [Name], [Url]) values
		(N'invoice',    N'Рахунок клієнту', N'invoice'),
		(N'waybillout', N'Видаткова накладна', N'waybillout')
	merge doc.DocumentForms as t
	using @df as s on t.Id = s.Id and t.TenantId = 1
	when matched then update set
		t.[Name] = s.[Name],
		t.[Url] = s.[Url]
	when not matched by target then insert
		(TenantId, Id, [Name], [Url]) values
		(1, s.Id, s.[Name], s.[Url])
	when not matched by source and t.TenantId = 1 then delete;
end
go


