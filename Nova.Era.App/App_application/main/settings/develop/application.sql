
------------------------------------------------
create or alter procedure app.[Application.Export.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Application!TApp!Object] = null, [!!Id] = 1,
		[AccKinds!AccKind!Array] = null;

	select [!TAccKind!Array] = null, [Uid!!Id] = Uid, [Name], Memo,
		[!TApp.AccKinds!ParentId] = 1
	from acc.AccKinds where TenantId = @TenantId and Void = 0;
end
go
------------------------------------------------
drop procedure if exists app.[Application.Upload.Metadata];
drop procedure if exists app.[Application.Upload.Update];
drop type if exists app.[Application.AccKind.TableType];
go
------------------------------------------------
create type app.[Application.AccKind.TableType] as table
(
	[Uid] uniqueidentifier,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure app.[Application.Upload.Metadata]
as
begin
	set nocount on;
	declare @AccKinds app.[Application.AccKind.TableType];
	select [AccKinds!Application.AccKinds!Metadata] = null, * from @AccKinds;

end
go
------------------------------------------------
create or alter procedure app.[Application.Upload.Update]
@TenantId int = 1,
@UserId bigint,
@AccKinds app.[Application.AccKind.TableType] readonly
as
begin
	set nocount on
	set transaction isolation level read committed;

	merge acc.AccKinds as t
	using @AccKinds as s
	on t.[Uid] = s.[Uid]
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo]
	when not matched by target then insert 
		([Uid], [Name], [Memo]) values
		(s.[Uid], s.[Name], s.[Memo]);

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @AccKinds for xml auto);
	throw 60000, @xml, 0;
	*/

	select [Result!TResult!Object] = null, [Success] = 1;

end
go
