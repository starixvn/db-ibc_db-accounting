ALTER PROCEDURE [DBA_ArchiveAccount2_Rollback]
	@AccName varchar(50),	
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created by: Theo
	Date:	2009-08-13
	Task: Rollback in STAGE 2 
	DB: DBTXN/BODB02
	Revisions:
		- 20091229@Jamie: Edit Rollback together with Custsetting and Custsetting3rd
		- 20100204@Jamie: Remove positiontakingallowday, positiontakingallowtime1,positiontakingallowtime2
		- 20100208@Kiwi: Remove UTN field.
		- 20100413@Kiwi: Remove custinfo.AffiliateID, customer.gender, customer.question, customer.answer, customer.transferoption fields
		- 20100512@Henry: append some new columns to the column list of table bodb_Customer.dbo.custinfo_old to insert back to table custinfo
		- 20100912@Thien: new fields for custinfo/custinfo_old: [DisableBingo],[DisableNumber],[SyncBingo],[MaxPerMatch161],[MaxPerMatch99MP]
		                    new fields for custsetting3rd_old: [alivepositiontaking],[mlivepositiontaking],[slivepositiontaking],[autolivepositiontaking],[isautolivepositiontaking],[autolivempositiontaking],[isautolivempositiontaking]
		- 20101019@Henry: Record execution time
		- 20101030@Henry: new fields for custinfo/custinfo_old: [MaxPerBall161]
		- 20110122@Henry: new fields for custinfo/custinfo_old: [MaxPerMatch151_AU], [MaxPerMatch152_UK], [MaxPerMatch152_AU], [MaxPerMatch153_AU], [Disable151_AU], [Disable152_UK], [Disable152_AU], [Disable153_AU]
		- 20111007@Tom: new fields for custinfo/custinfo_old: MaxtransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P.
		- 20111103@Lukas: restore in balance tables
		- 20111103@Lukas: apply for Live casino
		- 20120816@Dan: apply for VS
		- 20120821@Elodie: add new fields for custinfo/custinfo_old: Abnormal
		- 20121004@Johnson: add double comm losing status
		- 20121015@Dan: add fields for LCS-WinLimit (isAutoResetLiveCasino,MaxWinLiveCasino)
		- 20121204@Scott: add fields for virtual tennis (maxpermatch186)
		- 20130121@Johnson: change linked server DB05 to DBARCCUST
		- 20131108@Elodie: Splitting bodb02 into CustDB (Insert BalanceCredit, BalanceDebit by DBA_ArchiveAccount2_Rollback_Balance SP)
		- 20140403@Kathy: Insert data to columns: maxpermatch181,maxpermatch182,maxpermatch183,maxpermatch184,maxpermatch185 of bodb_Customer.dbo.custInfo_old
	NOTE: 
	--Review the SP again once executing as maybe new fields were added to customer or custinfo table
	--Generate and Run custsetting data manually, by using Local 204 Db or ask the backup DB from Joe
		--+Script can be done by SQL Studio for SQL Server - DB Extract for SQL server
	--Delete manually from bodb_Customer.dbo.customer_old and bodb_Customer.dbo.custinfo_old

*/

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

Declare @roleid int, @AgentID int, @Now datetime, @Enabled bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2,3,4)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END

if @Enabled = 1
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has NOT been archived!!', @ErrCode = 101
	print @ErrMsg
	return
END

print  @AccName +':'+ 'Start:' + convert(varchar(50), getdate(), 113)


--==========================================================
--CREATING TEMP TABLES
--==========================================================

	CREATE TABLE #Member (custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int)
	CREATE TABLE #Agent (recommend int PRIMARY KEY, mrecommend int, srecommend int)
	
	CREATE TABLE #Master (mrecommend int PRIMARY KEY, srecommend int)
		
	IF @roleid NOT IN (2,3,4) RETURN 0
		
	IF @roleid = 2
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM DBARCCUST.bodb_Customer.dbo.custinfo_old c (nolock)			
		WHERE  c.recommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend 
		FROM custinfo c (nolock)			
		WHERE  c.recommend = @AgentID AND c.roleid = 2		
		
	END
	IF @roleid = 3
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM DBARCCUST.bodb_Customer.dbo.custinfo_old c (nolock)		
		WHERE c.mrecommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend 
		FROM custinfo c (nolock)
		WHERE  c.mrecommend = @AgentID AND c.roleid = 2
		
		INSERT INTO #Master (mrecommend, srecommend)
		SELECT distinct c.mrecommend, c.srecommend
		FROM custinfo c (nolock)
		WHERE  c.mrecommend = @AgentID AND c.roleid = 3
		
	END
	IF @roleid = 4
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM DBARCCUST.bodb_Customer.dbo.custinfo_old c (nolock)
		WHERE c.srecommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend 
		FROM custinfo c (nolock)
		WHERE  c.srecommend = @AgentID AND c.roleid = 2
		
		INSERT INTO #Master (mrecommend, srecommend)
		SELECT distinct c.mrecommend, c.srecommend
		FROM custinfo c (nolock)
		WHERE  c.srecommend = @AgentID AND c.roleid = 3
	END
	

-----------------------------------------
--=============================
--PERFORM ROLLING BACK MEMBERS
--=============================
DECLARE	@Step INT, @minCustID INT, @maxCustID INT, @index INT
SELECT	@index = 0 
SELECT  @minCustID = MIN(CustID), @maxCustID = MAX(CustID) FROM #Member WITH (NOLOCK)
SELECT	@Step = 1000
--Copy back the customer and custinfo
WHILE (@minCustID + @Step*@index <= @maxCustID )
BEGIN
	EXEC bodb02.dbo.DBA_ArchiveAccount2_Rollback_Balance @minCustID = @minCustID, @Step = @Step, @index = @index, @AgentID = @AgentID, @roleid = @roleid

	SET IDENTITY_INSERT customer ON
		insert into customer (
			custid, firstname, lastname, address, postal, city, state, country, phone, mobilephone, 
			fax, email, birthday, refcode1, refcode2, remark, creatdate, creator, username, currency, 
			userpwd, lastlogged, pwdexpiry, roleid, mrecommend, recommend, ugroup, logincount, on_sessionid, site, 
			iplogin, important, srecommend, username2
		)
		select 
			custid, firstname, lastname, address, postal, city, state, country, phone, mobilephone, 
			fax, email, birthday, refcode1, refcode2, remark, creatdate, creator, username, currency, 
			userpwd, lastlogged, pwdexpiry, roleid, mrecommend, recommend, ugroup, logincount, on_sessionid, site, 
			iplogin, important, srecommend, username2
		from	DBARCCUST.bodb_Customer.dbo.customer_old with(nolock)
		where	custid IN (	select	custid from #Member WITH (NOLOCK) 
							where	custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
						)
	SET IDENTITY_INSERT customer OFF

	insert into custinfo (
			username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, 
			autosuspend, reject, credit, closed, MatchLimit, VirtualMultiplier, maxpermatch, maxpermatch2, 
			maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12, maxpermatch99, [Enabled],
			danger,maxpermatch151,maxpermatch201,DisableHorseRacing,DisableFinancial,DisableCasino,SyncCasino,danger2,danger3,DisableOutright,
			DisableOpenTote,maxpermatch151_OT,[DisableBingo]
          ,[DisableNumber]
          ,[SyncBingo]
          ,[MaxPerMatch161]
          ,[MaxPerMatch99MP]
          ,[MaxPerBall161]
          ,[MaxPerMatch151_AU]
		  ,[MaxPerMatch152_UK]
          ,[MaxPerMatch152_AU]
		  ,[MaxPerMatch153_AU]
		  ,[Disable151_AU], [Disable152_UK], [Disable152_AU], [Disable153_AU]
		  , MaxtransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P, DisableLiveCasino, SyncLiveCasino
		  , maxpermatch180, DisableVirtualSports, HideVirtualSports, maxpermatch186
		  , Abnormal
		  , DoubleCommLosing
		  ,isAutoResetLiveCasino, MaxWinLiveCasino  
		  ,maxpermatch181
		  ,maxpermatch182
		  ,maxpermatch183
		  ,maxpermatch184
		  ,maxpermatch185
          )
			
			
	SELECT  username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, 
			autosuspend, reject, credit, closed, MatchLimit, VirtualMultiplier, maxpermatch, maxpermatch2, 
			maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12, maxpermatch99,  [Enabled],
			danger,maxpermatch151,maxpermatch201,DisableHorseRacing,DisableFinancial,DisableCasino,SyncCasino,danger2,danger3,DisableOutright,
			DisableOpenTote,maxpermatch151_OT,[DisableBingo]
          ,[DisableNumber]
          ,[SyncBingo]
          ,[MaxPerMatch161]
          ,[MaxPerMatch99MP]
          ,[MaxPerBall161]
          ,[MaxPerMatch151_AU]
          ,[MaxPerMatch152_UK]
		  ,[MaxPerMatch152_AU]
          ,[MaxPerMatch153_AU]
          ,[Disable151_AU], [Disable152_UK], [Disable152_AU], [Disable153_AU]
          , MaxtransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P, DisableLiveCasino, SyncLiveCasino
          , maxpermatch180, DisableVirtualSports, HideVirtualSports, maxpermatch186
          , Abnormal
          , DoubleCommLosing
          ,isAutoResetLiveCasino, MaxWinLiveCasino   
		  ,maxpermatch181
		  ,maxpermatch182
		  ,maxpermatch183
		  ,maxpermatch184
		  ,maxpermatch185
	from	DBARCCUST.bodb_Customer.dbo.custinfo_old with(nolock)
	where	custid IN (	select	custid from #Member WITH (NOLOCK) 
						where	custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
					)
	SELECT	@index = @index + 1 
	WAITFOR DELAY '000:00:02'
END 

-----------------------
--Update back the enabled to 1
-----------------------
update custinfo set enabled = 1 where custid IN(select recommend from #Agent)

if @roleid >= 3 
	update custinfo set enabled = 1 where custid IN(select mrecommend from #Master)
	
if @roleid = 4
BEGIN
	update custinfo set enabled = 1 where custid IN(select distinct srecommend from #Master)
	
	IF @@ROWCOUNT = 0
		update custinfo set enabled = 1 where custid = @AgentID
END
---------------------------
--ROLLBACK CustSetting and CustSetting3rd 
---------------------------
SELECT	@Step = 20,@index = 0 
WHILE (@minCustID + @Step*@index <= @MaxCustID )
BEGIN
	INSERT INTO CustSetting(
		custid, 
		bettype, 
		sporttype, 
		apositiontaking, 
		mpositiontaking, 
		spositiontaking, 
		alivepositiontaking, 
		mlivepositiontaking, 
		slivepositiontaking,
		playerdiscount, 
		discount, 
		adiscount, 
		sdiscount, 
		groupa, 
		groupb, 
		groupc, 
		groupd, 
		groupe, 
		groupf, 
		minbet, 
		maxbet, 
		autopositiontaking,
		autolivepositiontaking, 
		isautopositiontaking, 
		isautolivepositiontaking, 
		autompositiontaking, 
		autolivempositiontaking, 
		isautompositiontaking,
		isautolivempositiontaking
	)
	SELECT	custid, 
			bettype, 
			sporttype, 
			apositiontaking, 
			mpositiontaking, 
			spositiontaking, 
			alivepositiontaking, 
			mlivepositiontaking, 
			slivepositiontaking,
			playerdiscount, 
			discount, 
			adiscount, 
			sdiscount, 
			groupa, 
			groupb, 
			groupc, 
			groupd, 
			groupe, 
			groupf, 
			minbet, 
			maxbet, 
			autopositiontaking,
			autolivepositiontaking, 
			isautopositiontaking, 
			isautolivepositiontaking, 
			autompositiontaking, 
			autolivempositiontaking, 
			isautompositiontaking,
			isautolivempositiontaking
	FROM	DBARCCUST.bodb_Customer.dbo.CustSetting_old WITH (NOLOCK)
	WHERE	custid IN (	SELECT	custid FROM #Member WITH (NOLOCK)
						WHERE	custid BETWEEN @minCustID + @Step*@index AND (@minCustID - 1) + @Step*(@index + 1)) 

	INSERT INTO CustSetting3rd(
	   [custid]
	  ,[bettype]
	  ,[sporttype]
	  ,[apositiontaking]
	  ,[mpositiontaking]
	  ,[spositiontaking]
	  ,[playerdiscount]
	  ,[discount]
	  ,[adiscount]
	  ,[sdiscount]
	  ,[minbet]
	  ,[maxbet]
	  ,[autopositiontaking]
	  ,[isautopositiontaking]
	  ,[autompositiontaking]
	  ,[isautompositiontaking]
	  ,[alivepositiontaking]
      ,[mlivepositiontaking]
      ,[slivepositiontaking]
      ,[autolivepositiontaking]
      ,[isautolivepositiontaking]
      ,[autolivempositiontaking]
      ,[isautolivempositiontaking]
	)
	SELECT [custid]
		  ,[bettype]
		  ,[sporttype]
		  ,[apositiontaking]
		  ,[mpositiontaking]
		  ,[spositiontaking]
		  ,[playerdiscount]
		  ,[discount]
		  ,[adiscount]
		  ,[sdiscount]
		  ,[minbet]
		  ,[maxbet]
		  ,[autopositiontaking]
		  ,[isautopositiontaking]
		  ,[autompositiontaking]
		  ,[isautompositiontaking]
		  ,[alivepositiontaking]
          ,[mlivepositiontaking]
          ,[slivepositiontaking]
          ,[autolivepositiontaking]
          ,[isautolivepositiontaking]
          ,[autolivempositiontaking]
          ,[isautolivempositiontaking]
	FROM	DBARCCUST.bodb_Customer.dbo.CustSetting3rd_Old WITH (NOLOCK)
	WHERE	custid IN (	SELECT	custid FROM #Member WITH (NOLOCK)
						WHERE	custid BETWEEN @minCustID + @Step*@index AND (@minCustID - 1) + @Step*(@index + 1)) 
	SELECT	@index = @index + 1
	WAITFOR DELAY '000:00:02'
END

SELECT	@index = 0 , @Step = 1000 ;
---------------------------
--ROLLBACK CustSetting and CustSetting3rd 
---------------------------
WHILE (@minCustID + @Step*@index <= @maxCustID )
BEGIN
	insert into [dbo].[P2PGameSetting](
			[CustID] ,
			[Bettype] ,
			[StakeLevel1] ,
			[StakeLevel2] ,
			[StakeLevel3] ,
			[StakeLevel4] ,
			[StakeLevel5]
			)
	Select 	[CustID] ,
			[Bettype] ,
			[StakeLevel1] ,
			[StakeLevel2] ,
			[StakeLevel3] ,
			[StakeLevel4] ,
			[StakeLevel5]
	FROM DBARCCUST.bodb_Customer.dbo.P2PGameSetting_Old  WITH (NOLOCK)
		where	custid IN (	select	custid from #Member WITH (NOLOCK) 
						where	custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
					)

	insert into [dbo].[P2PGroupComm] (
			[CustID],
			[GroupID],
			[sdiscount],
			[adiscount],
			[discount],
			[playerdiscount]
			)
	Select 	[CustID],
			[GroupID],
			[sdiscount],
			[adiscount],
			[discount],
			[playerdiscount]
	FROM DBARCCUST.bodb_Customer.dbo.P2PGroupComm_Old WITH (NOLOCK)
		where	custid IN (	select	custid from #Member WITH (NOLOCK) 
						where	custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
					)

	SELECT	@index = @index + 1 
	WAITFOR DELAY '000:00:02'
END
------------------
---- Live Casino

SELECT	@index = 0 , @Step = 1000 ;
---------------------------
--ROLLBACK CustSetting 
---------------------------
WHILE (@minCustID + @Step*@index <= @maxCustID )
BEGIN
	insert into [dbo].[custsettingGame](CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking)
		Select 	CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking
		FROM DBARCCUST.bodb_Customer.dbo.CustSettingGame_Old  WITH (NOLOCK)
		where	custid IN (	select	custid from #Member WITH (NOLOCK) 
						where	custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
					)

	SELECT	@index = @index + 1 
	WAITFOR DELAY '000:00:02'
END

declare @LogSPData varchar(4000)
Select @LogSPData = '<DBA_ArchiveAccount2_Rollback AccName="'+ coalesce(cast(@AccName as varchar(50)),space(1))+ '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))  + '"/>'
					
set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)
					
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1504,
	@TrackingValue = @LogSPData	,
	@duration = @duration


GO
GRANT EXECUTE ON [dbo].[DBA_ArchiveAccount2_Rollback] TO [bodbadminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount2_Rollback] TO [vnteam] AS [dbo]