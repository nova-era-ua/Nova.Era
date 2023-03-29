-- TEST timetable
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'hr')
	exec sp_executesql N'create schema hr';
go
------------------------------------------------
grant execute on schema::hr to public;
go
------------------------------------------------
/*
create table hr.HrDocDetails (
	Id bigint
);
go
create table hr.HrDocDetailsData (
	Id bigint,
	Row bigint, -- ref to rows
	Date date -- key,
	Code bigint, -- timecode
	Duration int -- minutes
)
*/
------------------------------------------------
create or alter procedure hr.[TimeTable.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docid bigint = 1;
	declare @docdate date = N'20230301';

	declare @rows table(Id bigint);
	declare @tbdata table([Row] bigint, [Day] int, Code bigint, Duration int);
	declare @codes table(Id bigint, [Code] nvarchar(2), HasTime bit);

	insert into @codes (Id, [Code], HasTime)
	values
		(10, N'Р', 1),
		(11, N'ВЧ', 1),
		(12, N'РН', 1);

	insert into @rows(Id)
	values
		(10),
		(11),
		(12),
		(13),
		(14),
		(15);

	insert into @tbdata([Row], [Day], [Code], Duration) 
	values
		(10, 1,  10, 480),
		(10, 1,  11, 120),
		(10, 1,  12, 120),
		(10, 18, 10, 480),
		(10, 18, 11, 120),
		(11, 3,  10, 480),
		(11, 4,  10, 480),
		(11, 20, 10, 480),
		(11, 21, 10, 480),
		(12, 5,  10, 480),
		(12, 6,  10, 480);

	select [Document!TDocument!Object] = null, [Id!!Id] = @docid, [Date] = @docdate,
		 [Rows!TRow!Array] = null;

	select [!TRow!Array] = null, [Id!!Id] = Id,
		[RowData!TRowData!CrossObject] = null,
		[!TDocument.Rows!ParentId] = @docid
	from @rows
	order by Id;	

	with TD as (select Id = [Row] * 10000 + [Day], [Row], [Day] from @tbdata group by [Row], [Day])
	select [!TRowData!CrossObject] = null, [Id!!Id] = Id, [!!Key] = [Day],
		[DayData!TDayData!Array] = null,
		[!TRow.RowData!ParentId] = [Row]
	from TD
	order by [Row], [Day];

	select [!TDayData!Array] = null, Code, Duration, [Day],
		[!TRowData.DayData!ParentId] = [Row] * 10000 + [Day]
	from @tbdata
	order by [Code];

	select [Codes!TCode!Array] = null, [Id!!Id] = Id, [Code],  HasTime
	from @codes
	order by Id;
end
go
