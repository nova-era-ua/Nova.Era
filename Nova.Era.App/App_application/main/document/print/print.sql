------------------------------------------------
create or alter procedure doc.[Document.Print.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [PrintForms!TPrintForm!Array] = null, [Id!!Id] = 0, DocumentId = @Id,		
		[Name!!Name] = pf.[Name], pf.Category, pf.[Url], pf.Report
	from.doc.Documents d
		inner join doc.Operations op on d.TenantId = op.TenantId and d.Operation = op.Id
		inner join doc.OpPrintForms lnk on op.TenantId = lnk.TenantId and lnk.Operation = op.Id
		inner join doc.PrintForms pf on lnk.TenantId = pf.TenantId and lnk.PrintForm = pf.Id
	where d.TenantId = @TenantId and d.Id = @Id
	order by pf.[Order];
end
go
------------------------------------------------
create or alter procedure doc.[Document.Stock.Report]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- all rows

	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date] = d.[Date], d.SNo, d.Memo,
		d.[Sum], [Agent!TAgent!RefId] = d.Agent,
		[Company!TCompany!RefId] = d.Company, [WhFrom!TWarehouse!RefId] = d.WhFrom,
		[WhTo!TWarehouse!RefId] = d.WhTo, [Contract!TContract!RefId] = d.[Contract], 
		[Rows!TRow!Array] = null
	from doc.Documents d
	where TenantId = @TenantId and Id = @Id;

	declare @rows table(id bigint, item bigint, unit bigint, rowno int);
	insert into @rows (id, item, unit, rowno)
	select Id, Item, Unit, row_number() over(order by dd.Kind desc, RowNo)
	from doc.DocDetails dd	
	where dd.TenantId = @TenantId and dd.Document = @Id;

	select [!TRow!Array] = null, [Id!!Id] = dd.Id, [Qty], Price, [Sum], ESum, DSum, TSum,
		[Item!TItem!RefId] = dd.Item, [Unit!TUnit!RefId] = dd.Unit, 
		[!TDocument.Rows!ParentId] = dd.Document, [RowNo!!RowNumber] = r.rowno
	from doc.DocDetails dd
		inner join @rows r on dd.Id = r.id
	where dd.TenantId=@TenantId and dd.Document = @Id
	order by r.rowno;

	-- maps
	select [!TWarehouse!Map] = null, [Id!!Id] = w.Id, [Name!!Name] = w.[Name]
	from cat.Warehouses w inner join doc.Documents d on d.TenantId = w.TenantId and w.Id in (d.WhFrom, d.WhTo)
	where d.Id = @Id and d.TenantId = @TenantId
	group by w.Id, w.[Name];

	exec doc.[Document.MainMaps] @TenantId = @TenantId, @UserId=@UserId, @Id = @Id;

	with T as (select item from @rows group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name], Article, Barcode
	from cat.Items i inner join T on i.Id = T.item and i.TenantId = @TenantId
	where i.TenantId = @TenantId;

	with T as (select unit from @rows group by unit)
	select [!TUnit!Map] = null, [Id!!Id] = u.Id, u.Short
	from cat.Units u inner join T on u.Id = T.unit and u.TenantId = @TenantId
	where u.TenantId = @TenantId;
end
go