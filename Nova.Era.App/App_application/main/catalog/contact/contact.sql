-- Contact
drop procedure if exists cat.[Contact.Maps];
drop type if exists cat.[Contact.Index.TableType]
go
-------------------------------------------------
create type cat.[Contact.Index.TableType] as table
(
	rowno int identity(1, 1), 
	id bigint, 
	rowcnt int
);
go
-------------------------------------------------
create or alter procedure cat.[Contact.Maps]
@TenantId int = 1,
@Elems cat.[Contact.Index.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	-- maps
	/*
	with T as (select agent from @Elems group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a 
		inner join T t on a.TenantId = @TenantId and a.Id = agent;

	with T as (select comp from @Elems group by comp)
	select [!TCompany!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
	from cat.Companies c 
		inner join T t on c.TenantId = @TenantId and c.Id = comp;

	with T as (select pkind from @Elems group by pkind)
	select [!TPriceKind!Map] = null, [Id!!Id] = pk.Id, [Name!!Name] = pk.[Name]
	from cat.PriceKinds pk 
		inner join T t on pk.TenantId = @TenantId and pk.Id = pkind;

	with T as (select kind from @Elems group by kind)
	select [!TContactKind!Map] = null, [Id!!Id] = ck.Id, [Name!!Name] = ck.[Name]
	from cat.ContactKinds ck 
		inner join T t on ck.TenantId = @TenantId and ck.Id = kind;
	*/
end
go
-------------------------------------------------
create or alter procedure cat.[Contact.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(255) = N'date',
@Dir nvarchar(20) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';

	declare @cnts cat.[Contact.Index.TableType];

	insert into @cnts(id, rowcnt)
	select c.Id,
		count(*) over()
	from cat.Contacts c
	where c.TenantId = @TenantId and c.Void = 0
		and (@fr is null or c.[Name] like @fr or c.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order 
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then c.[Name]
				when N'memo' then c.[Memo]
			end
		end desc
	offset @Offset rows fetch next @PageSize rows only
	option (recompile);

	select [Contacts!TContact!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Memo],
		c.Birthday, c.Gender, c.Position,
		[!!RowCount] = t.rowcnt
	from @cnts t inner join 
		cat.Contacts c on c.TenantId = @TenantId and c.Id = t.id
	order by t.rowno;

	-- maps
	exec cat.[Contact.Maps] @TenantId, @cnts;

	select [!$System!] = null, [!Contacts!Offset] = @Offset, [!Contacts!PageSize] = @PageSize, 
		[!Contacts!SortOrder] = @Order, [!Contacts!SortDir] = @Dir,
		[!Contacts.Fragment!Filter] = @Fragment;
end
go
-------------------------------------------------
create or alter procedure cat.[Contact.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Contact!TContact!Object] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Memo,
		c.Position, c.Birthday
	from cat.Contacts c
	where c.TenantId = @TenantId and c.Id = @Id;

end
go
-------------------------------------------------
drop procedure if exists cat.[Contact.Metadata];
drop procedure if exists cat.[Contact.Update];
drop type if exists cat.[Contact.TableType];
go
-------------------------------------------------
create type cat.[Contact.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	Memo nvarchar(255),
	[Position] nvarchar(255),
	Gender nchar(1),
	Birthday date,
	Country nchar(3)
)
go
------------------------------------------------
create or alter procedure cat.[Contact.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Contact cat.[Contact.TableType];
	select [Contact!Contact!Metadata] = null, * from @Contact;
end
go
------------------------------------------------
create or alter procedure cat.[Contact.Update]
@TenantId int = 1,
@UserId bigint,
@Contact cat.[Contact.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Contacts as t
	using @Contact as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.Position = s.Position,
		t.UtcDateModified = getutcdate(),
		t.UserModified = @UserId
	when not matched by target then insert
		(TenantId, [Name], Memo, Position, 
			UserCreated, UserModified, UtcDateModified) values
		(@TenantId, s.[Name], s.Memo, Position,
		    @UserId, @UserId, getutcdate())
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;
	exec cat.[Contact.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go

-------------------------------------------------
create or alter procedure cat.[Contact.Delete]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read committed;
	update cat.Contacts set Void = 1 where TenantId = @TenantId and Id=@Id;
end
go

-------------------------------------------------
create or alter procedure cat.[Contact.Fetch]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null,
@Agent bigint = null,
@Company bigint = null,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	set @Company = nullif(@Company, 0);
	set @Agent = nullif(@Agent, 0);

	declare @cnts cat.[Contact.Index.TableType];

	insert into @cnts(id)
	select top(100) c.Id	
	from cat.Contacts c
	where c.TenantId = @TenantId and c.Void = 0
		and (c.[Name] like @fr or c.Memo like @fr);

	select [Contacts!TContact!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.[Memo],
		c.Birthday, c.Gender, c.Position
	from @cnts t inner join 
		cat.Contacts c on c.TenantId = @TenantId and c.Id = t.id;
	-- maps
	exec cat.[Contact.Maps] @TenantId, @cnts;

end
go
