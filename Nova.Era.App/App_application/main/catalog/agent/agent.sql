/* Agent */
-------------------------------------------------
create or alter procedure cat.[Agent.Index]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Agents!TAgent!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo], [Tags!TTag!Array] = null
	from cat.Agents a
	where TenantId = @TenantId and [Partner] = 1

	select [!TTag!Array] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color,
		[!TAgent.Tags!ParentId] = ta.Agent
	from cat.TagsAgent ta inner join cat.Tags t on ta.TenantId = t.TenantId and ta.Tag = t.Id
	order by t.Id;
end
go
-------------------------------------------------
create or alter procedure cat.[Agent.Load]
@TenantId int = 1,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Agent!TAgent!Object] = null, [Id!!Id] = a.Id, [Name!!Name] = [Name],
		FullName, [Memo], IsSupplier, IsCustomer,
		[Contacts!TContact!Array] = null,
		[Tags!TTag!Array] = null
	from cat.Agents a
	where TenantId = @TenantId and Id = @Id;

	select [!TContact!Array] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name], c.Birthday, c.Gender,
		c.Position,
		[!TAgent.Contacts!ParentId] = ac.Agent
	from cat.Contacts c
		inner join cat.AgentContacts ac on c.TenantId = ac.TenantId and c.Id = ac.Contact
	where ac.TenantId = @TenantId and ac.Agent = @Id;

	select [!TTag!Array] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color,
		[!TAgent.Tags!ParentId] = ta.Agent
	from cat.TagsAgent ta 
		inner join cat.Tags t on ta.TenantId = t.TenantId and ta.Tag = t.Id
	where ta.Agent = @Id;

	exec cat.[Tag.For] @TenantId =@TenantId, @UserId = @UserId, @For = N'Agent';
end
go
-------------------------------------------------
drop procedure if exists cat.[Agent.Metadata];
drop procedure if exists cat.[Agent.Update];
drop type if exists cat.[Agent.TableType];
drop type if exists cat.[Agent.Contact.TableType];
go
-------------------------------------------------
create type cat.[Agent.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[FullName] nvarchar(255),
	[Memo] nvarchar(255),
	IsCustomer bit,
	IsSupplier bit
)
go
------------------------------------------------
create type cat.[Agent.Contact.TableType]
as table (
	Id bigint null,
	Position nvarchar(255)
);
go
------------------------------------------------
create or alter procedure cat.[Agent.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Agent cat.[Agent.TableType];
	declare @Contacts cat.[Agent.Contact.TableType];
	declare @Tag a2sys.[Id.TableType];
	select [Agent!Agent!Metadata] = null, * from @Agent;
	select [Tags!Agent.Tags!Metadata] = null, * from @Tag;
	select [Contacts!Agent.Contacts!Metadata] = null, * from @Contacts;
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Update]
@TenantId int = 1,
@UserId bigint,
@Agent cat.[Agent.TableType] readonly, 
@Contacts cat.[Agent.Contact.TableType] readonly,
@Tags a2sys.[Id.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	/*
	declare @xml nvarchar(max);
	set @xml = (select * from @Tags for xml auto);
	throw 60000, @xml, 0;
	*/

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Agents as t
	using @Agent as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[FullName] = s.[FullName],
		t.IsCustomer = s.IsCustomer,
		t.IsSupplier = s.IsSupplier,
		t.[Partner] = 1
	when not matched by target then insert
		(TenantId, [Name], FullName, Memo, IsCustomer, IsSupplier, [Partner]) values
		(@TenantId, s.[Name], s.FullName, s.Memo, s.IsCustomer, s.IsSupplier, 1)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	with CT as (
		select * from cat.AgentContacts where TenantId=@TenantId and Agent = @id
	)
	merge CT as t
	using @Contacts as s
	on t.TenantId = @TenantId and t.Contact = s.Id
	--when matched then update
	when not matched by target then insert
		(TenantId, Agent, Contact) values
		(@TenantId, @id, s.Id)
	when not matched by source then delete;

	with TT as (
		select * from cat.TagsAgent where TenantId = @TenantId and Agent = @id
	)
	merge TT as t
	using @Tags as s
	on t.TenantId = @TenantId and t.Tag = s.Id
	when not matched by target then insert
		(TenantId, Agent, Tag) values
		(@TenantId, @id, s.Id)
	when not matched by source and t.Agent = @id and t.TenantId = @TenantId
	then delete;

	exec cat.[Agent.Load] @TenantId = @TenantId, @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Fetch]
@TenantId int = 1,
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Agents!TAgent!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name], a.Memo, a.FullName
	from cat.Agents a
	where TenantId = @TenantId and Void = 0 and a.[Partner] = 1 and
		([Name] like @fr or Memo like @fr or FullName like @fr)
	order by a.[Name];
end
go
