/*
initial catalog
*/
-- currencies
------------------------------------------------
begin
set nocount on;

declare @crc table(Id bigint, [Alpha3] nchar(3), [Number3] nchar(3), [Symbol] nvarchar(3), [Denom] int, [Name] nvarchar(255));

insert into @crc (Id, Alpha3, Number3, [Symbol], Denom, [Name]) values
(980, N'UAH', N'980', N'₴', 1, N'Українська гривня'),
(840, N'USD', N'840', N'$', 100, N'Долар США'),
(978, N'EUR', N'978', N'€', 100, N'Євро'),
(826, N'GBP', N'826', N'£', 100, N'Британський фунт стерлінгов'),
(756, N'CHF', N'756', N'₣', 100, N'Швейцарський франк'),
(985, N'PLN', N'985', N'Zł',100, N'Польський злотий');

merge cat.Currencies as t
using @crc as s on t.Id = s.Id and t.TenantId = 0
when matched then update set
	t.[Alpha3] = s.[Alpha3],
	t.[Number3] = s.[Number3],
	t.[Symbol] = s.[Symbol],
	t.Denom = s.Denom,
	t.[Name] = s.[Name]
when not matched by target then insert
	(TenantId, Id, Alpha3, Number3, [Symbol], Denom, [Name]) values
	(0, s.Id, s.Alpha3, s.Number3, s.[Symbol], s.Denom, s.[Name])
when not matched by source and t.TenantId = 0 then delete;
end
go
