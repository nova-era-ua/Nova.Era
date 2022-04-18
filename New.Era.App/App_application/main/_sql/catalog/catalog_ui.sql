-- user interface
------------------------------------------------
if not exists(select * from a2sys.SysParams where [Name] = N'AppTitle')
	insert into a2sys.SysParams ([Name], StringValue) values (N'AppTitle', N'Nova.Era');
else
	update a2sys.SysParams set StringValue = N'Nova.Era' where [Name] = N'AppTitle';
go
