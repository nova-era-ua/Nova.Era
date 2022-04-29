-- MIGRATIONS

if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Currencies' and COLUMN_NAME=N'Symbol')
begin
	alter table cat.Currencies add Symbol nvarchar(3);
	alter table cat.Currencies drop column [Char];
end
go

drop table if exists cat.ItemTreeItems;
drop procedure if exists cat.[Item.Folder.Metadata];
drop procedure if exists cat.[Item.Folder.Update];
drop procedure if exists cat.[Item.Folder.Load];
drop type if exists cat.[Item.Folder.TableType];
drop procedure if exists cat.[Item.Item.Load];
drop procedure if exists cat.[Item.Item.Metadata];
drop procedure if exists cat.[Item.Item.Update];
drop type if exists cat.[Item.Item.TableType];
drop procedure if exists cat.[Item.Expand];
drop procedure if exists cat.[Item.Children];
drop procedure if exists cat.[Item.Index];
drop procedure if exists doc.[Operation.Children];
go
