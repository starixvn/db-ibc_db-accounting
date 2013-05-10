ALTER  PROCEDURE [dbo].[DBA_CreateLicenseeAgent]
	@LicenseeName varchar(50),
	@SuperWildCard varchar(50),
	@Currency int = 0,
	@IsSpecial bit = 0,
	@IsDeposit INT = 1
AS
/*
	Created by: [20110127@Henry]
	Task: Create Licensee and the Agents for that Licensee
	DB: DB052.bodb_Licensee
	Param's Explanation:
	+ @LicenseeName example: 12BET
	+ @SuperWildCard example: 12BETSuper%
	+ @Currency (default is 0: all currency) if <> 0 then will insert the agents for that currency only
	+ @IsSpecial: if 1 then update column Description to normal, or affiliate or banner depend on:
	- username ending with 01: normal
	- username ending with 02: affiliate
	- username ending with 03: banner
	- username ending with 04: income access
	Revisions:
	- 20120509@Henry: add 1 more param: @IsDeposit (default = 1)
	- 20120611@Henry: only get from real agent (condition: username NOT like @LicenseeName + 'ACC%')
*/

declare @LicenseeID int
declare @agent as table (
LicenseeID int,
CustID int,
UserName varchar(100),
RoleID int,
Currency int,
CurrencyName varchar(100),
[Description] varchar(100)
)



declare @super as table(
CustID int
)

--insert new Licensee and get the ID
if not exists (select 1 from Licensees (nolock) where LicenseeName = @LicenseeName)
begin
	SELECT @LicenseeID=max(licenseeid)+1 FROM licensees WITH (NOLOCK)

	insert into Licensees (LicenseeID,LicenseeName,IsDeposit) values (@LicenseeID,@LicenseeName,@IsDeposit)
end
else
begin
	select @LicenseeID = LicenseeID from Licensees (nolock) where LicenseeName = @LicenseeName
end

IF ISNULL(@LicenseeID,0)=0
RAISERROR('Licensee could not found, please have a check!',16,1)

--get the superid
if @Currency = 0
BEGIN
	insert into @super (CustID)
	select custid from bodb02.dbo.custinfo (nolock)
	where roleid = 4
	and username like @SuperWildCard
END
ELSE
BEGIN
	insert into @super (CustID)
	select custid from bodb02.dbo.custinfo (nolock)
	where roleid = 4
	and username like @SuperWildCard
	and currency = @Currency
END

--get the licensee Agents
IF @LicenseeName='12BET'
BEGIN
	insert into @agent (LicenseeID, CustID,Username, RoleID, Currency,CurrencyName,[Description])
	select 
		@LicenseeID, custid, username, roleid, c.currency,
		case c.currency when 20 then 'UUS' else e.Code end as currencyName,
		'' as [description]
	from bodb02.dbo.custinfo c (nolock) inner join bodb02.dbo.exchange e (nolock) on c.currency = e.exchangeid
	where 
	srecommend in ( select custid from @super)
	and roleid = 2 
	and username not like '12BETAFF%'
	and username not like '12BETTAFF%'
	and username not like '12BETACC%'
END
ELSE
BEGIN
	insert into @agent (LicenseeID, CustID,Username, RoleID, Currency,CurrencyName,[Description])
	select 
		@LicenseeID, custid, username, roleid, c.currency,
		case c.currency when 20 then 'UUS' else e.Code end as currencyName,
		'' as [description]
	from bodb02.dbo.custinfo c (nolock) inner join bodb02.dbo.exchange e (nolock) on c.currency = e.exchangeid
	where 
		srecommend in ( select custid from @super)
		and roleid = 2 
		and username NOT like @LicenseeName + 'ACC%'
END

--Update description
if @IsSpecial=1 
BEGIN
	--01: normal
	Update @agent
	set [Description] = 'normal'
	where substring(Username,len(Username)-1,2) = '01'
	
	--02: affiliate
	Update @agent
	set [Description] = 'affiliate'
	where substring(Username,len(Username)-1,2) = '02'
	
	--03: banner
	Update @agent
	set [Description] = 'banner'
	where substring(Username,len(Username)-1,2) = '03'
	
	Update @agent
	set [Description] = 'income access'
	where substring(Username,len(Username)-1,2) = '04'
	 
END


--insert licenseecust
insert into LicenseeCust(LicenseeID,CustID,RoleID,Currency,CurrencyName,[Description])
select A.LicenseeID,A.CustID,A.RoleID,A.Currency,A.CurrencyName,A.[Description] from @agent A
where not exists (
select * from licenseecust B (nolock) 
where 
A.LicenseeID = B.LicenseeID 
and A.custid = B.custid 
and A.roleid = B.roleid 
and A.currency = B.currency)

GO
GRANT EXECUTE ON [dbo].[DBA_CreateLicenseeAgent] TO [vnteam]