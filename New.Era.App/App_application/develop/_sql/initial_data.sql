/*
initial data
*/

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