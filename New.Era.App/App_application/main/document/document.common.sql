/* Document.Common */
------------------------------------------------
create or alter procedure doc.[Document.MainMaps] 
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [!TRespCenter!Map] = null, [Id!!Id] = rc.Id, [Name!!Name] = rc.[Name]
	from cat.RespCenters rc inner join doc.Documents d on d.TenantId = rc.TenantId and d.RespCenter = rc.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	select [!TContract!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Date], c.[SNo],
		[PriceKind!TPriceKind!RefId] = c.PriceKind, [Company!TCompany!RefId] = c.Company, 
		[Agent!TAgent!RefId] = c.Agent
	from doc.Contracts c inner join doc.Documents d on d.TenantId = c.TenantId and d.[Contract] = c.Id
	where d.Id = @Id and d.TenantId = @TenantId;

	with TA as (
		select Agent from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id
		union all
		select c.Agent from doc.Documents d inner join doc.Contracts c on c.TenantId = d.TenantId and c.Id = d.[Contract]
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a
	where a.TenantId = @TenantId and a.Id in (select Agent from TA);

	with CA as(
		select Company from doc.Documents d where d.TenantId = @TenantId and d.Id = @Id
		union all
		select c.Company from doc.Documents d inner join doc.Contracts c on c.TenantId = d.TenantId and c.Id = d.[Contract]
		where d.TenantId = @TenantId and d.Id = @Id
	)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
	where c.TenantId = @TenantId and c.Id in (select Company from CA);

	select [LinkedDocs!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done],
		[OpName] = o.[Name], [Form] = o.Form, [!TDocument.LinkedDocs!ParentId] = d.Parent
	from doc.Documents d 
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Parent = @Id;

	select [!TDocBase!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], d.[Done],
		[OpName] = o.[Name], o.Form
	from doc.Documents p inner join doc.Documents d on d.TenantId = p.TenantId and d.Parent = p.Id
	inner join doc.Operations o on p.TenantId = o.TenantId and p.Operation = o.Id
	where d.Id = @Id and d.TenantId = @TenantId;
end
go
------------------------------------------------
create or alter procedure doc.[Document.DeleteTemp]
@TenantId int =1,
@UserId bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from doc.DocDetails from
		doc.DocDetails dd inner join doc.Documents d on dd.TenantId = d.TenantId and  dd.Document = d.Id
			where d.TenantId = @TenantId and d.UserCreated = @UserId and d.Temp = 1 and [Date] < dateadd(day, 1, getdate());
	delete from doc.Documents where TenantId = @TenantId and UserCreated = @UserId and Temp = 1
		and [Date] < dateadd(day, 1, getdate());
end
go
-------------------------------------------------
create or alter procedure doc.[Document.Rems.Get]
@TenantId int = 1,
@UserId bigint,
@Items nvarchar(max),
@Date date,
@CheckRems bit = 1,
@Wh bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @items a2sys.[Id.TableType];
	insert into @items (Id) 
		select [value] from string_split(@Items, N',');

	select [Rems!TRem!Array] = null, r.Item, r.Rem
	from doc.fn_getItemsRems(@CheckRems, @TenantId, @items, @Date, @Wh) r;
end
go

