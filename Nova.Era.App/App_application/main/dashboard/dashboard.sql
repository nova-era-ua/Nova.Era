/* DASHBOARD */
------------------------------------------------
create or alter procedure app.[Dashboard.Load]
@TenantId int = 1,
@UserId bigint,
@Kind nvarchar(16)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @id bigint;

	select @id = Id from app.Dashboards 
	where TenantId = @TenantId and [User] = @UserId and Kind = @Kind;
	if @@rowcount = 0
	begin
		insert into app.Dashboards (TenantId, [User], [Kind]) values (@TenantId, @UserId, @Kind);
		select @id = Id from app.Dashboards 
		where TenantId = @TenantId and [User] = @UserId and Kind = @Kind;
	end

	select [Dashboard!TDashboard!Object] = null, [Id!!Id] = d.Id, Kind,
		[Items!TDashboardItem!Array] = null, [Widgets!TWidget!LazyArray] = null
	from app.Dashboards d 
	where TenantId = @TenantId and [User] = @UserId and Kind = @Kind;

	select [!TDashboardItem!Array] = null, [Id!!Id] = di.Id, di.[row], di.[col], di.rowSpan, di.colSpan,
		di.Widget, w.[Url], [Params!!Json] = di.Params, [!TDashboard.Items!ParentId] = di.Dashboard
	from app.DashboardItems di 
	inner join app.Widgets w on di.TenantId = w.TenantId and di.Widget = w.Id
	where di.TenantId = @TenantId and di.Dashboard = @id;

	select [!TWidget!Array] = null, w.[Name], [row] = 0, col = 0, w.rowSpan, w.colSpan, w.[Url],
		[Widget] = w.Id, w.Icon, w.Memo, [Params]
	from app.Widgets w where 0 <> 0;
end
go
-------------------------------------------------
create or alter procedure app.[Dashboard.Widgets]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @kind nvarchar(16);
	select @kind = Kind from app.Dashboards where TenantId = @TenantId and Id = @Id;

	select [Widgets!TWidget!Array] = null, w.[Name], [row] = 0, col = 0, w.rowSpan, w.colSpan, w.[Url],
		[Widget] = w.Id, Icon, Memo, Params
	from app.Widgets w 
	where w.TenantId = @TenantId and Kind = @kind
	order by w.Id;
end
go
-------------------------------------------------
drop procedure if exists app.[Dashboard.Metadata];
drop procedure if exists app.[Dashboard.Update];
drop type if exists app.[Dashboard.TableType];
drop type if exists app.[DashboardItem.TableType];
go
------------------------------------------------
create type app.[Dashboard.TableType] as table 
(
	Id bigint null,
	Kind nvarchar(16)
);
go
------------------------------------------------
create type app.[DashboardItem.TableType] as table
(
	Id bigint,
	[row] int,
	[col] int,
	Widget bigint,
	Params nvarchar(1023)
);
go
-------------------------------------------------
create or alter procedure app.[Dashboard.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @Dashboard app.[Dashboard.TableType];
	declare @Items app.[DashboardItem.TableType];

	select [Dashboard!Dashboard!Metadata] = null, * from @Dashboard;
	select [Items!Dashboard.Items!Metadata] = null, * from @Items;
end
go
-------------------------------------------------
create or alter procedure app.[Dashboard.Update]
@TenantId int = 1,
@UserId bigint,
@Dashboard app.[Dashboard.TableType] readonly,
@Items app.[DashboardItem.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @id bigint;
	declare @kind nvarchar(16);

	select @id = Id, @kind = Kind from @Dashboard;

	/*
	declare @xml nvarchar(max);
	select @xml = (select * from @Items for xml auto);
	throw 60000, @xml, 0;
	*/
	with T as (
		select Id = i.Id, i.[row], i.col, w.rowSpan, w.colSpan, Widget = i.Widget, i.Params
			from @Items i inner join app.Widgets w on w.TenantId = @TenantId and w.Id = i.Widget
	)
	merge app.DashboardItems as t
	using T as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[row] = s.[row],
		t.[col] = s.[col]
	when not matched by target then insert
		(TenantId, Dashboard, Widget, [row], col, rowSpan, colSpan, Params) values
		(@TenantId, @id, s.Widget, s.[row], s.[col], s.rowSpan, s.colSpan, s.Params)
	when not matched by source and t.TenantId = @TenantId and t.Dashboard = @id then delete;
	
	exec app.[Dashboard.Load] @TenantId = @TenantId, @UserId = @UserId, @Kind = @kind;
end
go
