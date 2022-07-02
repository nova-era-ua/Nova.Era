
------------------------------------------------
create or alter procedure doc.[Document.Stock.Report]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date] = d.[Date], d.SNo, d.Memo,
		d.[Sum],
		[StockRows!TRow!Array] = null
	from doc.Documents d
	where TenantId = @TenantId and Id = @Id;

	declare @rows table(id bigint, item bigint, unit bigint, [role] bigint, costitem bigint);
	insert into @rows (id, item, unit, [role], costitem)
	select Id, Item, Unit, ItemRole, CostItem from doc.DocDetails dd
	where dd.TenantId = @TenantId and dd.Document = @Id;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], Price, [Sum], ESum, DSum, TSum,
		[Item!TItem!RefId] = dd.Item, [Unit!TUnit!RefId] = Unit, 
		[!TDocument.StockRows!ParentId] = dd.Document, [RowNo!!RowNumber] = RowNo
	from doc.DocDetails dd
	where dd.TenantId=@TenantId and dd.Document = @Id and dd.Kind = N'Stock'
	order by RowNo;

	with T as (select item from @rows group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], Article, Barcode,
		[Unit.Id!TUnit!Id] = i.Unit, [Unit.Short!TUnit!] = u.Short
	from cat.Items i inner join T on i.Id = T.item and i.TenantId = @TenantId
		left join cat.Units u on i.TenantId = u.TenantId and i.Unit = u.Id
	where i.TenantId = @TenantId;
end
go