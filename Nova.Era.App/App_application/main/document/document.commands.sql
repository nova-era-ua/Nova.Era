﻿/* Document Commands */
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

	declare @operation bigint, @parent bigint, @linktype nchar(1), @linkkind nvarchar(16), @factor smallint;
	select @parent = ol.Parent, @operation = ol.Operation, @linktype = okpr.LinkType, @linkkind = okch.Kind, @factor = okch.Factor
	from doc.OperationLinks ol 
		inner join doc.Operations opr on ol.TenantId = opr.TenantId and ol.Parent = opr.Id
		inner join doc.Operations och on ol.TenantId = och.TenantId and ol.Operation = och.Id
		left join doc.OperationKinds okpr on ol.TenantId = okpr.TenantId and opr.Kind = okpr.Id
		left join doc.OperationKinds okch on ol.TenantId = okch.TenantId and och.Kind = okch.Id
	where ol.TenantId = @TenantId and ol.Id = @LinkId;

	declare @BaseDoc bigint;
	declare @ParentDoc bigint;
	if @linktype = N'P'
	begin
		-- base = base from parent
		select @BaseDoc = Base, @ParentDoc = @Document from doc.Documents where TenantId = @TenantId and Id = @Document;
	end
	else if @linktype = N'B'
	begin
		-- base = parent
		set @BaseDoc = @Document;
		set @ParentDoc = @Document;
	end

	declare @alreadysum money, @baseSum money;
	select @baseSum = isnull([Sum], 0) from doc.Documents d where d.TenantId = @TenantId and d.Id = @BaseDoc;
	-- calc remainder sum
	select @alreadysum = isnull(sum(d.[Sum] * d.BindFactor), 0) 
		from doc.Documents d where TenantId = @TenantId and d.Temp = 0 and
			Base = @BaseDoc and d.BindKind = @linkkind;

	insert into doc.Documents (TenantId, [Date], Operation, Parent, Base, BindKind, BindFactor, OpLink, Company, Agent, [Contract], [RespCenter], 
		PriceKind, WhFrom, WhTo, Currency, UserCreated, Temp, [Sum])
	output inserted.Id, inserted.Operation into @rtable(id, op)
	select @TenantId, cast(getdate() as date), @operation, @ParentDoc, @BaseDoc, @linkkind, @factor, @LinkId, Company, Agent, [Contract], [RespCenter], 
		PriceKind, WhFrom, WhTo, Currency, @UserId, 1, @baseSum - @alreadysum
	from doc.Documents where TenantId = @TenantId and Id = @Document and Operation = @parent;

	select [Document!TDocBase!Object] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done],
		[OpName] = o.[Name], [Form] = o.Form, [DocumentUrl] = o.DocumentUrl
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
create or alter procedure doc.[Document.Copy]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @rtable table(id bigint);
	declare @newid bigint;

	begin tran;

	insert into doc.Documents (TenantId, Temp, [Date],  Operation, [Sum],  SNo, Company, Agent, [Contract], Currency, 
		WhFrom, WhTo, CashAccFrom, CashAccTo, RespCenter, ItemRole, CostItem, CashFlowItem, PriceKind, Notice, Memo, 
		UserCreated)
	output inserted.Id into @rtable(id)
	select @TenantId, 1, [Date], Operation, [Sum], SNo, Company, Agent, [Contract], Currency, 
		WhFrom, WhTo, CashAccFrom, CashAccTo, RespCenter, ItemRole, CostItem, CashFlowItem, PriceKind, Notice, Memo,
		@UserId
	from doc.Documents where TenantId = @TenantId and Id = @Id;
	
	select @newid = id from @rtable;

	insert into doc.DocDetails (TenantId, Document, RowNo, Kind, Item, ItemRole, ItemRoleTo, Unit,
		Qty, FQty, Price, [Sum], ESum, DSum, TSum, Memo, CostItem)
	select @TenantId, @newid, RowNo, Kind, Item, ItemRole, ItemRoleTo, Unit,
		Qty, FQty, Price, [Sum], ESum, DSum, TSum, Memo, CostItem
	from doc.DocDetails where TenantId = @TenantId and Document = @Id;
	commit tran;

	select [Document!TDocCopy!Object] = null, Id = @newid, o.DocumentUrl
	from doc.Documents d inner join doc.Operations o on d.TenantId = @TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Id = @newid;

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
		update doc.Documents set Base = null, BindKind = null, BindFactor = null where TenantId = @TenantId and Base = @Id;
		update doc.Documents set Parent = null where TenantId = @TenantId and Parent = @Id;
		delete from doc.Documents where TenantId = @TenantId and Id=@Id;
		commit tran;
	end
end
go
-------------------------------------------------
create or alter procedure doc.[ItemRole.Rem.Get]
@TenantId int = 1,
@UserId bigint,
@Item bigint = null,
@Role bigint = null,
@Date datetime = null,
@CheckRems bit = 1,
@Wh bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @elems a2sys.[Id.TableType];
	insert into @elems (Id) values (@Item);

	select [Result!TRem!Object] = null, r.Item, r.Rem, r.[Role]
	from doc.fn_getItemsRems(@CheckRems, @TenantId, @elems, @Date, @Wh) r
	where r.[Role] = @Role;
end
go
-------------------------------------------------
create or alter procedure doc.[Document.Base.Set]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@Base bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	-- assigns Base, BindKind, BindFactor

	declare @parentOp bigint;
	select @parentOp = Operation from doc.Documents where TenantId = @TenantId and Id = @Base;

	declare @kind nvarchar(16), @factor smallint;
	select @kind = ok.Kind, @factor = ok.Factor
	from doc.Documents d inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
		inner join doc.OperationKinds ok on ok.TenantId = o.TenantId and ok.Id = o.Kind
		inner join doc.OperationLinks ol on ol.TenantId = o.TenantId and ol.Operation = d.Operation
	where d.Id = @Id and ol.Parent = @parentOp;

	if @kind is null or @factor is null
		throw 60000, N'[Document.Base.Set]. Internal error', 0;

	update doc.Documents set Base = @Base, BindKind = @kind, BindFactor = @factor
	where TenantId = @TenantId and Id = @Id;
end
go

-------------------------------------------------
create or alter procedure doc.[Document.Base.Clear]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update doc.Documents set Base = null, BindKind = null, BindFactor = null 
	where TenantId = @TenantId and Id = @Id;
end
go

------------------------------------------------
create or alter procedure doc.[Document.SetState]
@TenantId int = 1,
@UserId bigint,
@Id bigint,
@State bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update doc.Documents set [State] = @State where TenantId = @TenantId and Id = @Id;
end
go

