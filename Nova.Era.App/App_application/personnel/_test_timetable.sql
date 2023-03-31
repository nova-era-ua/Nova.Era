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
create or alter procedure hr.[TimeBoard.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @docid bigint = 1;
	declare @docdate date = N'20230301';

	declare @rows table(Id bigint, RowNo int);
	declare @tbdata table([Row] bigint, [Day] int, Code bigint, Duration int);
	declare @codes table(Id bigint, [Code] nvarchar(2), [Type] int, Color nvarchar(32), [Name] nvarchar(255));

	insert into @codes (Id, [Code], [Type], Color, [Name])
	values
		(10, N'Р',  0,  null, N'Робочий час'),
		(11, N'ВЧ', 1, null, N'Вечірні'),
		(12, N'РН', 1, null, N'Нічні'),
		(13, N'НУ', 1, null, N'Надурочні'),
		(14, N'РВ', 1, null, N'Вихідні та святкові'),
		(21, N'ВД', 2, N'lemon', N'Відрядження'),
		(22, N'В',  2, N'green', N'Щорічна основна відпустка'),
		(23, N'ТН', 2, N'teal', N'Тимчасова непрацездатність'),
		(24, N'ІН', 2, N'gold', N'Держобов''язки'),
		(25, N'ДД', 2, N'blue', N'Відпустка по догляду за дитиною')

	insert into @rows(Id, RowNo)
	values
		(10, 1),
		(11, 2),
		(12, 3),
		(13, 4),
		(14, 5),
		(15, 6),
		(16, 7),
		(17, 8),
		(18, 9),
		(19, 10),
		(20, 11),
		(21, 12),
		(22, 13),
		(23, 14),
		(24, 15),
		(25, 16),
		(26, 17),
		(27, 18),
		(28, 19),
		(29, 20),
		(30, 21);

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

	select [!TRow!Array] = null, [Id!!Id] = Id, [RowNo!!RowNumber] = RowNo,
		[Days!TDay!MapObject!1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20:21:22:23:24:25:26:27:28:29:30:31] = null,
		[!TDocument.Rows!ParentId] = @docid
	from @rows
	order by Id;	

	with TD as (select Id = /**/[Row] * 10000 + [Day], [Row], [Day] from @tbdata group by [Row], [Day])
	select [!TDay!MapObject] = null, [Id!!Id] = Id, [!!Key] = [Day],
		[DayData!TDayData!Array] = null,
		[!TRow.Days!ParentId] = [Row]
	from TD
	order by [Row], [Day];

	select [!TDayData!Array] = null, Code, Duration, [Day],
		[!TDay.DayData!ParentId] = /**/[Row] * 10000 + [Day]
	from @tbdata
	order by [Code];

	select [Codes!TCode!Array] = null, [Id!!Id] = Id, [Code], [Type], [Color], [Name]
	from @codes
	order by Id;
end
go
