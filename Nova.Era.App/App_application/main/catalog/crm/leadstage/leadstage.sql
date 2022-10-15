/* LeadStage */
drop procedure if exists crm.[LeadStage.Metadata];
drop procedure if exists crm.[LeadStage.Update];
drop type if exists crm.[LeadStage.TableType];
drop type if exists crm.[LeadStageAccount.TableType];
go
------------------------------------------------
create type crm.[LeadStage.TableType] as table
(
	Id bigint,
	[Name] nvarchar(255),
	[Color] nvarchar(32),
	[Memo] nvarchar(255),
	[Order] int,
	[Kind] nchar(1)
)
go
------------------------------------------------
create or alter procedure crm.[LeadStage.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Kind nvarchar(16) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Stages!TStage!Array] = null,
		[Id!!Id] = ls.Id, [Name!!Name] = ls.[Name], ls.Color, ls.[Order], ls.Memo, ls.Kind
	from crm.LeadStages ls
	where ls.TenantId = @TenantId and ls.Void = 0
	order by ls.[Order];
end
go
------------------------------------------------
create or alter procedure crm.[LeadStage.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Stage!TStage!Object] = null,
		[Id!!Id] = ls.Id, [Name!!Name] = ls.[Name], ls.Color, ls.[Order], ls.Memo, ls.Kind
	from crm.LeadStages ls
	where ls.TenantId = @TenantId and ls.Id = @Id;

	select [Params!TParam!Object] = null, [NextOrdinal] = isnull(max([Order]), 0) + 1
	from crm.LeadStages 
	where TenantId = @TenantId;
end
go
---------------------------------------------
create or alter procedure crm.[LeadStage.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Role crm.[LeadStage.TableType];
	select [Stage!Stage!Metadata] = null, * from @Role;
end
go
---------------------------------------------
create or alter procedure crm.[LeadStage.Update]
@TenantId int = 1,
@UserId bigint,
@Stage crm.[LeadStage.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @output  table (op sysname, id bigint);
	declare @id bigint;

	merge crm.LeadStages as t
	using @Stage as s on (t.TenantId = @TenantId and t.Id = s.Id)
	when matched then update set
		t.[Name] = s.[Name], 
		t.Color = s.Color,
		t.Memo = s.Memo,
		t.[Order] = s.[Order],
		t.Kind = s.Kind
	when not matched by target then insert
		(TenantId, [Name], Color, Memo, [Order], Kind) values
		(@TenantId, s.[Name], s.Color, s.Memo, s.[Order],s.Kind)
	output $action, inserted.Id into @output (op, id);

	select top(1) @id = id from @output;
	
	exec crm.[LeadStage.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
---------------------------------------------
create or alter procedure crm.[LeadStage.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if @Id < 100
		throw 60000, N'UI:@[Error.Delete.System]', 0;
	if exists(select * from crm.Leads where Stage = @Id)
		throw 60000, N'UI:@[Error.Delete.Used]', 0;
	update crm.LeadStages set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

