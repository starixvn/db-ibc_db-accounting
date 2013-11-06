ALTER PROCEDURE [dbo].[Acc_CustomerSelAllInfo]
	@username varchar(30)
AS

/*
Created: 
Task : Get move bet day, balanceup day
DB: DBAGE/bodb02
Original:Accounting site

Revisions:
	- 20080925@PhuongDao: Calculate Balance with correct date instead of date - 1 
		- Add yesterday balance info
		- Web calculation (for current balance & yesterday balance):
		- Balance (general) = self cash + total downline cash
		- Agent balance = his cash + total cash of his members
		- Master balance = his cash + total cash of his agents + total cash of his members
		- Super balance = his cash + total cash of his masters  + total cash of his agents + total cash of his members
	- Dung@20081021 : Get ci.danger field instead of ci.dangercust in General info block	
	- Khoa@20090312 : Get ci.autosuspend field 
	- Qui@20090317 : Get ci.disablecasino, ci.synccasino field
	- 20090320@PhuongDao: Get the auto-suspend status of the upline. 
    - Shifu@20090324: Get c.site, customer's site information
	- 20090325@PhuongDao: Get the HR, FI status of Downlines under the customer
	- 20090401@Shifu: Get member website base agent website
	- 20090701@Phuc: get disableautoMPT.
	- 20090717@pluto: get danger2, danger3.
	- 20090729@Simon: get Status DisableOutRight.
	- 20090731@pluto:get Enabled status: Member, Agent, Master, Super
	- 20100505@pluto:get DisableDownlinesOpenTote status
	- 20100608@pluto:get DisableDownlinesCasino status
	- 20100619@Thien: get custID from Username on DB06, via f_GetCustIDFromUsername function
	- 201000909@Ethan:get  DisableBingo, DisableDownlinesBI, syncbingo, DisableDownlinesNumber, DisableNumber  status
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20101015@Ethan: Get Limited Per IP value @LimitPerIP + SelectedBetting
	- 20110315@Johnson: remove get status Horse Racing
	- 20110429@Lukas: get downline statistics (number of Active, closed, suspended)
	- 20110516@Lukas: re-arrange bettype
	- 20110718@Sophia: because username2 add prefix 'Agency$', so hide the prefix when select username2
	- 20110721@Sophia: remove prefix 'Agency$' when select username2
	- 20110822@Elly: - Correct Turnover of sports book since Sep 01, 2011
	- 20120131@Johnson: Get DisableLiveCasino, SyncLiveCasino status, currencyid
	- 20120302@Jim: add more isBA column in General info return
	- 20120504@Dom: add more IsDeposit column in General info return
	- 20120423@Lukas: check if roleid > 4 then return
	- 20120815@Sophia: Get DisableVirtualSports, HideVirtualSports, DisableDownlinesVirtualSports
	- 20120822@Elodie: Get Abnormal field
	- 20120927@Johnson: Get double comm losing status
	- 20130121@Dan: change linked server DB06 to DBARC, DB052 to DBLIC
	- 20130322@Ethan:Get column NicknameLoginOnly for Super, Master, Agent
	- 20130422@Johnson: get field LastChangedSecurityCodeDate
	- 20130719@Elodie: Correct link server DBACC instead of DBARC
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	
Param's Explanation:
	@username: username want to get all info related
*/		


SET NOCOUNT ON
Declare @custid int, @uplineid int, @roleid tinyint, @UsedCredit MONEY, @DisableDownlinesHR BIT, @DisableDownlinesOpenTote BIT, @DisableDownlinesFI BIT,@DisableDownlinesCS BIT,@DisableDownlinesBI BIT,
@DisableDownlinesNumber BIT, @DisableDownlinesLiveCS BIT, @DisableDownlinesHRFixedOdds BIT, @DisableDownlinesVirtualSports BIT,
@DownlinesSelectedBetting BIT, @IsInternal BIT,  @LimitPerIP tinyint,@SelectedBetting bit, @NicknameLoginOnly BIT, @LastChangedSecurityCodeDate DATETIME
Declare @todaySuperCash money,@todayMasterCash money, @todayAgentCash money, @todayCustCash money
Declare @currentDate DATETIME 
Declare @membersite varchar(10)
DECLARE @TotalMAgentActive INT,
		@TotalMAgentClosed INT,
		@TotalMAgentSuspended INT,
		@TotalAgentActive INT,
		@TotalAgentClosed INT,
		@TotalAgentSuspended INT,
		@TotalMemberActive INT,
		@TotalMemberClosed INT,
		@TotalMemberSuspended INT

DECLARE @NegativeBetEffectiveDate datetime
SET @NegativeBetEffectiveDate='2011-09-01'

Select @currentDate = convert(varchar(10), CURRENT_TIMESTAMP, 120)

--Get CustID from DB06, where got index on Username and Username2
Exec @custid = DBACC.bodb02.dbo.f_GetCustIDFromUsername @username
IF @custid is NULL
	RETURN
ELSE
	select @roleid = roleID from custinfo with (nolock) where custid = @custid

IF @roleid > 4
	RETURN
-----------------------------

SELECT @DisableDownlinesFI = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableFinancial,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableFinancial = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableFinancial,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableFinancial = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableFinancial,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableFinancial = 1) 											 
										  ELSE 0 END 	
										  
SELECT @DisableDownlinesCS = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableCasino,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableCasino = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableCasino,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableCasino = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableCasino,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableCasino = 1) 											 
										  ELSE 0 END

SELECT @DisableDownlinesBI = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableBingo,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableBingo = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableBingo,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableBingo = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableBingo,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableBingo = 1) 											 
										  ELSE 0 END				
			
SELECT @DisableDownlinesNumber = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableNumber,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableNumber = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableNumber,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableNumber = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableNumber,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableNumber = 1) 											 
										  ELSE 0 END	
										  
SELECT @DisableDownlinesLiveCS = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableLiveCasino,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableLiveCasino = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableLiveCasino,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableLiveCasino = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableLiveCasino,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableLiveCasino = 1) 											 
										  ELSE 0 END
										  
SELECT @DisableDownlinesHRFixedOdds= CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableHRFixedOdds,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableHRFixedOdds = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableHRFixedOdds,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableHRFixedOdds = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableHRFixedOdds,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableHRFixedOdds = 1) 											 
										  ELSE 0 END
										  
SELECT @DisableDownlinesVirtualSports = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableVirtualSports,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableVirtualSports = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableVirtualSports,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableVirtualSports = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableVirtualSports,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableVirtualSports = 1) 											 
										  ELSE 0 END									
										  										  							  
-------------------------------------------------------------------------
DECLARE @IsDeposit bit --Identify deposit customer
	SET @IsDeposit = 0

IF @roleid in (2,3,4)
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.Customer c WITH (NOLOCK)
							INNER JOIN dbo.Site s WITH (NOLOCK) ON c.site = s.site 
					WHERE custid = @custid
						  AND isLicensee =1)
	SET @IsDeposit =1
	
	SELECT @LastChangedSecurityCodeDate = LastChangedSecurityCodeDate
	FROM DBTXN.bodb02.dbo.CustLoginInfo WITH(NOLOCK)
	WHERE custid = @custid
END

--Get member site
IF @roleid = 1
BEGIN
	SELECT	@membersite = c.site, @uplineid = c.custid
	FROM	customer c with (nolock)
		INNER JOIN custinfo ci with (nolock) ON c.custid = ci.recommend
	WHERE ci.custid = @custid
	
	IF EXISTS (SELECT 1 FROM dbo.Customer c WITH (NOLOCK)
							INNER JOIN dbo.Site s WITH (NOLOCK) ON c.site = s.site 
					WHERE custid = @uplineid
						  AND isLicensee =1)

	SET @IsDeposit =1
	
	SELECT @LastChangedSecurityCodeDate = LastChangedDate
	FROM DBTXN.bodb02.dbo.CustLoginInfo_Member WITH(NOLOCK)
	WHERE custid = @custid
END

/*
--Get Internal status
SELECT @IsInternal = CASE @roleid WHEN 4 THEN (SELECT isnull(IsInternal, 0) FROM custSuper WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 3 THEN (SELECT isnull(IsInternal, 0) FROM custMaster WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 2 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @custid 		)
								  WHEN 1 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @uplineid)
								  ELSE 0 END 	
*/								  

SET @LimitPerIP = 0
SET @NicknameLoginOnly=0
SET @SelectedBetting = 0
SET @IsInternal = 0
SET @DownlinesSelectedBetting = 0

IF @roleid = 4 --super
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0),
		@LimitPerIP = isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0),
		@NicknameLoginOnly =isnull(NicknameLoginOnly, 0)
	FROM custSuper WITH (NOLOCK) WHERE custid = @custid
	
	SELECT TOP 1 @DownlinesSelectedBetting =  isnull(SelectedBetting,0) FROM custMaster WITH (NOLOCK)
	WHERE 
		custid IN (
					SELECT mrecommend FROM custinfo WITH (nolock)  
					WHERE 
						srecommend = @custid 
						AND roleid = 3
				  )

	SELECT
	@TotalMAgentActive = ISNULL(SUM(CASE WHEN RoleID = 3 and Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	@TotalMAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 3 and Closed = 1 THEN 1 ELSE 0 END), 0),
	@TotalMAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 3 and ISNULL(reject,0) = 1 and Closed = 0 THEN 1 ELSE 0 END), 0),
	
	@TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 and Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	@TotalAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 2 and Closed = 1 THEN 1 ELSE 0 END), 0),
	@TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 and ISNULL(reject,0) = 1 and Closed = 0 THEN 1 ELSE 0 END), 0),
	
	@TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 and Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	@TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 and Closed = 1 THEN 1 ELSE 0 END), 0),
	@TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 and ISNULL(reject,0) = 1 and Closed = 0 THEN 1 ELSE 0 END), 0)
	FROM Custinfo WITH (NOLOCK)
	WHERE SRecommend = @custid
END								  
ELSE IF @roleid = 3 --master
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0),
		@LimitPerIP = isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0),
		@NicknameLoginOnly =isnull(NicknameLoginOnly, 0)
	FROM custMaster WITH (NOLOCK) WHERE custid = @custid
	
	SELECT TOP 1 @DownlinesSelectedBetting =  isnull(SelectedBetting,0) FROM custAgent WITH (NOLOCK)
	WHERE 
		custid IN (
					SELECT recommend FROM custinfo WITH (nolock)  
					WHERE 
						srecommend = @custid 
						AND roleid = 2
				  )
	SELECT
	@TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 and Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	@TotalAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 2 and Closed = 1 THEN 1 ELSE 0 END), 0),
	@TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 and ISNULL(reject,0) = 1 and Closed = 0 THEN 1 ELSE 0 END), 0),
	
	@TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 and Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	@TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 and Closed = 1 THEN 1 ELSE 0 END), 0),
	@TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 and ISNULL(reject,0) = 1 and Closed = 0 THEN 1 ELSE 0 END), 0)
	FROM Custinfo WITH (NOLOCK)
	WHERE MRecommend = @custid
END
ELSE IF @roleid = 2 --agent
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0),
		@LimitPerIP = isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0),
		@NicknameLoginOnly =isnull(NicknameLoginOnly, 0)
	FROM custAgent WITH (NOLOCK) WHERE custid = @custid
	
	SELECT
	@TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 and Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	@TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 and Closed = 1 THEN 1 ELSE 0 END), 0),
	@TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 and ISNULL(reject,0) = 1 and Closed = 0 THEN 1 ELSE 0 END), 0)
	FROM Custinfo WITH (NOLOCK)
	WHERE Recommend = @custid
END
ELSE IF @roleid = 1 --member
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0)
	FROM custAgent WITH (NOLOCK) WHERE custid = @uplineid
END
								  	
--General info
DECLARE @isBA BIT
IF EXISTS (
			 SELECT 1 FROM DBLIC.bodb_Licensee.dbo.LicenseeBAHistory lb WITH (NOLOCK)
			 WHERE custid=@custid AND status='running'
			)
	SET @isBA=1
ELSE
	SET @isBA=0
select c.custid, c.username, c.firstname, c.lastname, 
	c.username2, 		
	ci.roleid, 
	lastlogged, 
	iplogin lastloginip, 
	pwdexpiry, 
	ci.credit, 
	e.currency,
	e.exchangeid,
	e.actualrate,
	ci.virtualmultiplier - 1 as virtualmultiplier,
	important,
	ci.danger,
	ci.danger2,
	ci.danger3,
	ci.Abnormal,
	ci.closed, ci.reject as suspended, ci.autosuspend,	
	ci.DisableFinancial,
	isnull(@DisableDownlinesFI,0) DisableDownlinesFI,
	isnull(@DisableDownlinesCS,0) DisableDownlinesCS,
	isnull(@DisableDownlinesBI,0) DisableDownlinesBI,
	isnull(@DisableDownlinesNumber,0) DisableDownlinesNumber,
	isnull(@DisableDownlinesLiveCS,0) DisableDownlinesLiveCS,
	isnull(@DisableDownlinesHRFixedOdds,0) DisableDownlinesHRFixedOdds,
	isnull(@DisableDownlinesVirtualSports,0) DisableDownlinesVirtualSports,
	isnull(@DownlinesSelectedBetting,0) DownlinesSelectedBetting,
	ci.DisableBingo,
	ci.DisableNumber,
	ci.DisableOutRight,
	ci.disablecasino,
	ci.synccasino,
	ci.syncbingo,
	ci.disableLiveCasino,
	ci.synclivecasino,
	ci.DisableHRFixedOdds,
	ci.DisableVirtualSports,
	ci.HideVirtualSports,
	ci.DoubleCommLosing,
	ci.Enabled,
	@isBA IsBA,
	@IsDeposit IsDeposit, 
	c.phone, c.mobilephone, c.fax, c.creatdate as createdate,
	c.site,
	@IsInternal as IsInternal,
	@LimitPerIP as LimitPerIP,
	@SelectedBetting as SelectedBetting,
	@NicknameLoginOnly as NicknameLoginOnly,
	@membersite as membersite,
	@LastChangedSecurityCodeDate as LastChangedSecurityCodeDate
from customer c with (nolock)
	inner join custinfo ci with (nolock) on c.custid = ci.custid
	inner join exchange e with (nolock) on c.currency = e.exchangeid 
where c.custid = @custid
----------------------------
-------------------------------------------------------------------------
--Agency Info
select case when c.roleid = 1 then c.custid else NULL end as memberID,
	case when c.roleid = 1 then c.username else NULL end as memberName,	
	case @roleid	when 1 then isnull(a.autosuspend,0) 
					when 2 then isnull(m.autosuspend,0) 
					when 3 then isnull(s.autosuspend,0) 
					else 0 end uplineAutosuspend,		
	a.custid as agentID,
	a.username as agentName,	
	a.Enabled as agentEnabled,
	m.custid as masterID,
	m.username as masterName,
	m.Enabled as masterEnabled,
	s.custid as superID,
	s.username as superName,
	s.Enabled as superEnabled
	
from custinfo c with (nolock)
	left join custinfo a with (nolock) on c.recommend = a.custid
	left join custinfo m with (nolock) on c.mrecommend = m.custid
	left join custinfo s with (nolock) on c.srecommend = s.custid
where
	c.custid = @custid
-------------------------------------------------------------------------
--Balance Info
if @roleid = 1
BEGIN
	/*
	SELECT @y_CustomerCash = sum(case when ruben=1 then winlost-actual_stake+playercomm else 0 end)
	FROM bettrans WITH(NOLOCK) 
	WHERE custid = @custid AND bettrans.winlostdate < convert(varchar(10), CURRENT_TIMESTAMP, 120)			
	*/
	
	SELECT @todayCustCash = ISNULL(SUM(winlost-actual_stake+playercomm) ,0)
	FROM dbo.bettrans with (nolock)
	WHERE custid = @custid and ruben = 1 and bettype < 19001 
		and winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)
	
	SELECT	isnull(Balance.Cash,0) Cash,
			isnull(Balance.Cash,0) - @todayCustCash yesterday_Cash,
			isnull(Balance.outstanding,0) outstanding,
			Balance.lastTxn lastTxn 
	FROM(		
		SELECT 
			isnull(sum(case when ruben=1 then winlost-actual_stake+playercomm else 0 end),0) Cash,
			sum(case when ruben=0 then CASE WHEN winlostdate<@NegativeBetEffectiveDate THEN actual_stake ELSE ABS(actual_stake)END else 0 end) outstanding, 
			max(transdate) lastTxn 
		FROM dbo.bettrans WITH(NOLOCK) 
		WHERE custid = @custid
	) Balance 

END 
else if @roleid = 2
BEGIN
	SELECT @UsedCredit = sum(credit)  
	FROM dbo.custinfo WITH(NOLOCK) 
	WHERE roleid=1 
		 AND recommend = @custid
	/*	 
	SELECT 
		@y_AgentCash = sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),
		@y_CustomerCash = sum(case when custid <> recommend and ruben=1 then winlost-actual_stake+playercomm else 0 end)
	FROM bettrans WITH(NOLOCK) 
	WHERE recommend = @custid AND bettrans.winlostdate < convert(varchar(10), CURRENT_TIMESTAMP, 120)			
	*/

	SELECT 	@todayAgentCash = ISNULL(SUM(awinlost+comm-playercomm),0),
			@todayCustCash = ISNULL(SUM(winlost-actual_stake+playercomm),0)
	FROM dbo.bettrans with (NOLOCK)
	WHERE  recommend = @custid and ruben = 1 and bettype < 19001 
		AND winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)
		
	SELECT	isnull(Balance.agentCash,0) agentCash,
			isnull(Balance.agentCash,0) - @todayAgentCash yesterday_agentCash,	
			isnull(Balance.agentPositionTaking,0) agentPositionTaking,
			isnull(Balance.customerCash,0) customerCash,
			isnull(Balance.customerCash,0) - @todayCustCash yesterday_customerCash,
			isnull(Balance.customerOutstanding,0) customerOutstanding,
			Balance.lastTxn lastTxn,
			@UsedCredit as agentUsedCredit
	FROM (	
		SELECT 
			sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
			sum(case when ruben=0 then actual_stake * apositiontaking else 0 end) agentPositionTaking, 
			sum(case when custid <> recommend and ruben=1 then winlost-actual_stake+playercomm else 0 end) customerCash, 
			sum(case when custid <> recommend and ruben=0 then actual_stake else 0 end) customerOutstanding, 
			max(transdate) lastTxn
		FROM dbo.bettrans WITH(NOLOCK) 
		WHERE recommend = @custid
	)Balance 

END
else if @roleid = 3
BEGIN
	Declare @DisableAutoMPT bit
	--Get disable auto MPT
	SELECT @DisableAutoMPT = DisableAutoMPT FROM CustMaster (nolock) WHERE CustID = @CustID
	
	SELECT @UsedCredit = sum(credit)  
	FROM custinfo WITH(NOLOCK) 
	WHERE roleid=2 
		AND mrecommend = @custid
	/*	
	SELECT 
		@y_MasterCash = sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),
		@y_AgentCash = sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),
		@y_CustomerCash = sum(case when custid <> recommend and custid <> mrecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end)
	FROM bettrans WITH(NOLOCK) 
	WHERE mrecommend = @custid AND bettrans.winlostdate < convert(varchar(10), CURRENT_TIMESTAMP, 120)			
	*/	
				
	SELECT	@todayMasterCash = isnull(sum(mwinlost+acomm-comm),0),
			@todayAgentCash  = isnull(sum(awinlost+comm-playercomm),0),
			@todayCustCash   = isnull(sum(winlost-actual_stake + playercomm ),0)
	FROM bettrans with (NOLOCK)
	WHERE mrecommend = @custid and ruben = 1 and bettype < 19001 
		and winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)
	
	SELECT	isnull(Balance.masterCash,0) masterCash,
			isnull(Balance.masterCash,0) - @todayMasterCash yesterday_masterCash,
			isnull(Balance.masterPositionTaking,0) masterPositionTaking,
			isnull(Balance.agentCash,0) agentCash,
			isnull(Balance.agentCash,0)- @todayAgentCash yesterday_agentCash,
			isnull(Balance.customerCash,0) customerCash,
			isnull(Balance.customerCash,0) - @todayCustCash yesterday_customerCash, 
			isnull(Balance.customerOutstanding,0) customerOutstanding,
			Balance.lastTxn lastTxn,
			@UsedCredit as masterUsedCredit,
			isnull(@DisableAutoMPT,0) as DisableAutoMPT
	FROM (	
		SELECT	sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end) masterCash,
				sum (case when ruben=0 then actual_stake * mpositiontaking else 0 end) masterPositionTaking, 
				sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
				sum(case when custid <> recommend and custid <> mrecommend and ruben=1 then winlost-actual_stake+playercomm else 0  end) customerCash, 
				sum(case when custid <> recommend and custid <> mrecommend and ruben=0 then actual_stake else 0 end) customerOutstanding, 
				max(transdate) lastTxn
		FROM bettrans WITH(NOLOCK) 
		WHERE mrecommend = @custid	
	)Balance 
	
	/*
	@TotalBalance = 
				IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
				+ IsNull(sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),0)
				+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end),0)

	FROM bettrans WITH (NOLOCK, index=bettrans16)  
	WHERE mrecommend=@CustID
	*/
END
else if @roleid = 4
BEGIN
	DECLARE @transid bigint, @transdate datetime
	SELECT @UsedCredit = sum(credit) 
	FROM custinfo WITH(NOLOCK)
	WHERE roleid=3
		 AND srecommend = @custid
	
	SELECT TOP 1 @transid = transid from bettrans with (nolock) where srecommend = @custid
	
	SELECT @transdate = max(transdate) from bettrans with (nolock) where transid = @transid
	
	SELECT	@todaySuperCash = isnull(sum(swinlost+scomm-acomm),0),
			@todayMasterCash = isnull(sum(mwinlost+acomm-comm),0),
			@todayAgentCash = isnull(sum(awinlost+comm-playercomm),0),
			@todayCustCash = isnull(sum(winlost-actual_stake+playercomm),0)
	FROM bettrans with (NOLOCK)
	WHERE srecommend = @custid and ruben = 1 and bettype < 19001 
		and winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)		
	
	SELECT	isnull(Balance.superCash ,0) superCash,
			isnull(Balance.superCash ,0)- @todaySuperCash yesterday_superCash,
			isnull(Balance.superPositionTaking,0) superPositionTaking,
			isnull(Balance.masterCash,0) masterCash,
			isnull(Balance.masterCash,0) - @todayMasterCash yesterday_masterCash,
			isnull(Balance.agentCash,0) agentCash,
			isnull(Balance.agentCash,0) - @todayAgentCash yesterday_agentCash,
			isnull(Balance.customerCash,0) customerCash,
			isnull(Balance.customerCash,0) - @todayCustCash yesterday_customerCash,
			isnull(Balance.customerOutstanding,0) customerOutstanding,
			@transdate  as lastTxn,
			@UsedCredit as superUsedCredit
	
	FROM (
		SELECT	sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end) superCash,
				sum(case when ruben=0 then actual_stake * spositiontaking else 0 end) superPositionTaking, 
				sum(case when custid=mrecommend then winlost-actual_stake 
											  else mwinlost+acomm-comm 
										 end)masterCash,
				sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
				sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end) customerCash, 
				sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=0 then actual_stake else 0 end) customerOutstanding	
		 FROM bettrans WITH(NOLOCK) 
		 WHERE srecommend = @custid
		)Balance 
 
END


SELECT  @TotalMAgentActive MAgentActive,
		@TotalMAgentClosed MAgentClosed,
		@TotalMAgentSuspended MAgentSuspended,
		@TotalAgentActive AgentActive,
		@TotalAgentClosed AgentClosed,
		@TotalAgentSuspended AgentSuspended,
		@TotalMemberActive MemberActive,
		@TotalMemberClosed MemberClosed,
		@TotalMemberSuspended MemberSuspended		
		

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelAllInfo] TO [vnteam] AS [dbo]