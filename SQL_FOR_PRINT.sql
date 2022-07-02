


create or alter procedure doc.[Document.Stock.Report]
@TenantId int = 1,
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date] = d.[Date], d.SNo, d.Memo,
		d.[Sum]
	from doc.Documents d
	where TenantId = @TenantId and Id = @Id;
end
go