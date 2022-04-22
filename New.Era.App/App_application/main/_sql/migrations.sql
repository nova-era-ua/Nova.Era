-- MIGRATIONS

if not exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Currencies' and COLUMN_NAME=N'Symbol')
begin
	alter table cat.Currencies add Symbol nvarchar(3);
	alter table cat.Currencies drop column [Char];
end
go

drop table if exists cat.ItemTreeItems;

