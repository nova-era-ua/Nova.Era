/* Document Commands */
------------------------------------------------
create or alter procedure doc.[Document.CreateOnBase.BySum]
@TenantId int = 1,
@UserId bigint,
@LinkId bigint,
@Document bigint,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @rtable table(id bigint, op bigint);

	declare @operation bigint, @parent bigint;
	select @parent = Parent, @operation = Operation from doc.OperationLinks where TenantId = @TenantId and Id=@LinkId

	insert into doc.Documents (TenantId, [Date], Operation, Parent, Base, OpLink, Company, Agent, [Contract], [RespCenter], 
		PriceKind, WhFrom, WhTo, Currency, UserCreated, Temp, [Sum])
	output inserted.Id, inserted.Operation into @rtable(id, op)
	select @TenantId, cast(getdate() as date), @operation, @Document, isnull(Base, @Document), @LinkId, Company, Agent, [Contract], [RespCenter], 
		PriceKind, WhFrom, WhTo, Currency, @UserId, 1, [Sum]
	from doc.Documents where TenantId = @TenantId and Id = @Document and Operation = @parent;

	select [Document!TDocBase!Object] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done],
		[OpName] = o.[Name], [Form] = o.Form
	from @rtable t inner join doc.Documents d on d.TenantId = @TenantId and t.id = d.Id
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id

	select top(1) @RetId = id from @rtable;
end
go
------------------------------------------------
create or alter procedure doc.[Document.CreateOnBase.ByRows]
@TenantId int = 1,
@UserId bigint,
@LinkId bigint,
@Document bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @newid bigint;

	exec doc.[Document.CreateOnBase.BySum] @TenantId = @TenantId, @UserId = @UserId, @LinkId = @LinkId, @Document = @Document,
		@RetId = @newid output;

	insert into doc.DocDetails (TenantId, Document, RowNo, Kind, Item, ItemRole, Unit, Qty, Price, [Sum], Memo,
		CostItem, ESum, DSum, TSum)
	select @TenantId, @newid, RowNo, Kind, Item, ItemRole, Unit, Qty, Price, [Sum], Memo,
		CostItem, ESum, DSum, TSum
	from doc.DocDetails where TenantId = @TenantId and Document = @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.CreateOnBase]
@TenantId int = 1,
@UserId bigint,
@Document bigint,
@LinkId bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @type nvarchar(16);
	select @type = [Type] from doc.OperationLinks where TenantId = @TenantId and Id = @LinkId;
	if @type = N'BySum'
		exec doc.[Document.CreateOnBase.BySum] @TenantId = @TenantId, @UserId = @UserId, @LinkId = @LinkId, @Document = @Document;
	else if @type = N'ByRows'
		exec doc.[Document.CreateOnBase.ByRows] @TenantId = @TenantId, @UserId = @UserId, @LinkId = @LinkId, @Document = @Document;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	declare @done bit;
	select @done = Done from doc.Documents where TenantId = @TenantId and Id=@Id;
	if @done = 1
		throw 600000, N'@[Error.Document.AlreadyApplied]', 0
	else
	begin
		begin tran;
		delete from doc.DocDetails where TenantId = @TenantId and Document=@Id;
		delete from doc.DocumentExtra where TenantId = @TenantId and Id=@Id;
		delete from doc.Documents where TenantId = @TenantId and Id=@Id;
		commit tran;
	end
end
go

