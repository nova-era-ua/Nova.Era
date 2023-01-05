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

	select [!TProject!Map] = null, [Id!!Id] = p.Id, [Name!!Name] = p.[Name]
	from cat.Projects p inner join doc.Documents d on d.TenantId = p.TenantId and d.Project = p.Id
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

end
go
------------------------------------------------
create or alter procedure doc.[Document.LinkedMaps] 
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [!TDocBase!Array] = null, [Id!!Id] = d.Id, d.[Date], d.[Sum], d.[Done], d.BindKind, d.BindFactor,
		[OpName] = o.[Name], [Form] = o.Form, o.DocumentUrl, [!TDocument.LinkedDocs!ParentId] = d.Parent
	from doc.Documents d 
		inner join doc.Operations o on d.TenantId = o.TenantId and d.Operation = o.Id
	where d.TenantId = @TenantId and d.Temp = 0 and d.Parent = @Id;

	select [!TDocBase!Map] = null, [Id!!Id] = p.Id, [Date] = p.[Date], p.[Sum], p.[Done], p.BindKind, p.BindFactor,
		[OpName] = o.[Name], o.Form, o.DocumentUrl
	from doc.Documents p inner join doc.Documents d on d.TenantId = p.TenantId and p.Id in (d.Parent, d.Base)
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

	declare @docs table(id bigint);	
	insert into @docs(id) 
	select Id from doc.Documents where TenantId = @TenantId and UserCreated = @UserId and Temp = 1;

	delete from doc.DocDetails from
		doc.DocDetails dd inner join @docs d on dd.TenantId = @TenantId and dd.Document = d.id
	update doc.Documents set Base = null, BindKind = null, BindFactor = null 
	where TenantId = @TenantId and Base in (select id from @docs);
	update doc.Documents set Parent = null where TenantId = @TenantId and Parent in (select id from @docs);

	delete from doc.Documents where Id in (select id from @docs);
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

	declare @itemstable a2sys.[Id.TableType];
	insert into @itemstable (Id) 
		select [value] from string_split(@Items, N',');

	select [Rems!TRem!Array] = null, r.Item, r.Rem, r.[Role]
	from doc.fn_getItemsRems(@CheckRems, @TenantId, @itemstable, @Date, @Wh) r;
end
go
------------------------------------------------
create or alter procedure doc.[Autonum.NextValue]
@TenantId int, 
@Company bigint, 
@Autonum bigint, 
@Date date, 
@Number nvarchar(64) output
as
begin
	set nocount on;
	set transaction isolation level read committed;

	if 0 = isnull(@Autonum, 0) or @Company is null
	begin
		set @Number = null;
		return;
	end
		

	declare @m int, @q int, @y int, @pattern nvarchar(255);
	declare @compprefix nvarchar(8);
	
	select @compprefix = isnull(AutonumPrefix, N'') from cat.Companies 
		where TenantId = @TenantId and Id=@Company;
	select @pattern = Pattern,
		@m = case when [Period] = N'M'  then month(@Date) else 0 end,
		@q = case when [Period] = N'Q'  then datepart(quarter, @Date) else 0 end,
		@y = case when [Period] <> N'A' then year(@Date) else 0 end
	from doc.Autonums where TenantId = @TenantId and Id = @Autonum;

	declare @rtable table(number int);
	begin tran;
		update doc.AutonumValues set CurrentNumber = CurrentNumber + 1 
			output inserted.CurrentNumber into @rtable(number)
		where TenantId = @TenantId and Company = @Company and Autonum = @Autonum 
			and [Year] = @y and Quart = @q and [Month] = @m;
	if @@rowcount = 0
		insert into doc.AutonumValues(TenantId, Company, Autonum, [Year], [Quart], [Month], CurrentNumber)
			output inserted.CurrentNumber into @rtable(number)
		values(@TenantId, @Company, @Autonum, @y, @q, @m, 1);
	commit tran;
	
	-- and format number
	declare @n int;
	select @n = number from @rtable;
	--select format(@n, replicate(N'0', 5));
	set @Number = replace(@pattern, N'{yy}', format(@Date, N'yy'));
	set @Number = replace(@Number, N'{yyyy}', format(@Date, N'yyyy'));
	set @Number = replace(@Number, N'{mm}', format(@Date, N'MM'));
	set @Number = replace(@Number, N'{qq}', format(datepart(quarter, @Date), N'00'));
	set @Number = replace(@Number, N'{p}', @compprefix);
	declare @p0 int, @p1 int, @patno nvarchar(255);
	set @p0 = charindex(N'{n', @Number);
	set @p1 = charindex(N'n}', @Number);
	if @p0 > 0 and @p1 > 0
		set @patno = replicate(N'0', @p1 - @p0);
	else
		set @patno = N'0';
	set @Number = stuff(@Number, @p0, @p1 - @p0 + 2, format(@n, @patno));
end
go

