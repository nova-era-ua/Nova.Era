------------------------------------------------
create or alter procedure erp.[Lead.OnCreatePartner] 
@Id bigint,
@RefKey uniqueidentifier
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;


	declare @partnerKey uniqueidentifier;
	declare @agentKey uniqueidentifier;
	select @partnerKey = PartnerKey from erp.ErpLeads where RefKey = @RefKey;
	declare @agentId bigint;
	select @agentId = Id, @agentKey = RefKeyAgent from cat.Agents where RefKeyPartner = @partnerKey;

	--select @partnerKey, @agentId, @agentKey;

	begin tran
	-- created agent for lead
	update cat.Leads set CreatedAgent = @agentId where Id=@Id;
	merge gas.AgentData as t
	using (
		select * from cat.Leads where Id = @Id
	) as s
	on t.Id = s.CreatedAgent
	when not matched by target then insert
		(Id, Branch, Region, IsTrader, Source, Seasonality, BalanceCond, OfferedCond,
			DesiredFrom, DesiredTo, YearVolume, GasOperator) values
		(CreatedAgent, Branch, Region, IsTrader, Source, Seasonality, BalanceCond, OfferedCond,
			DesiredFrom, DesiredTo, YearVolume, GasOperator);

	commit tran

end
go

exec erp.[Lead.OnCreatePartner] 109, N'77912191-3D9B-11ED-A56E-00155D000315';


