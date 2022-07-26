-- MIGRATIONS
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Operations' and COLUMN_NAME=N'DocumentUrl')
	alter table doc.Operations add DocumentUrl nvarchar(255) null;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'Forms' and COLUMN_NAME=N'Url')
	alter table doc.Forms add [Url] nvarchar(255);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'doc' and TABLE_NAME=N'DocDetails' and COLUMN_NAME=N'FQty')
	alter table doc.DocDetails add FQty float not null
		constraint DF_DocDetails_FQty default(0) with values;
go
