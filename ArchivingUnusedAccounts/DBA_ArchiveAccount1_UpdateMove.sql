ALTER PROCEDURE [dbo].[DBA_ArchiveAccount1_UpdateMove]
	@AccName varchar(50),
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created by: Theo
	Date: 2009-30-07
	Task: Moving data from custsetting to custsetting_old 
	DB: DBCUST/CustDB
	
	Revisions:
		- 20091222@Jamie: separate 3rd custsetting to custsetting3rd_old 
		- 20100107@Kiwi: Amend writing log.
		- 20100912@Thien: new fields for custsetting3rd_old: [alivepositiontaking],[mlivepositiontaking],[slivepositiontaking],[autolivepositiontaking],[isautolivepositiontaking],[autolivempositiontaking],[isautolivempositiontaking]
		- 20101019@Henry: Record execution time
		- 20111007@Tom: Include table of P2P Game: P2PGameSetting_Old, P2PGroupComm_Old
		- 20120227@Lukas: archive data for Live Casino Game
		- 20121005@Thien: change connection of bodb_Customer to DB05
		- 20130121@Johnson: change linked server DB05 to DBARCCUST
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call Acc_ExecRep_Cust_01 instead of Acc_ExecRep_01)
		- 20140618@Elodie: archive data for Keno
		- 20150514@Elodie: archive data for CustVirtualRate
		- 20151118@Billy: Archive data for CustVirtualSetting - [Redmine: #47729]
*/
    
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

Declare @roleid int, @AgentID int, @Enabled bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END

if @Enabled = 0
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has been archived!!', @ErrCode = 101
	print @ErrMsg
	return
END

print  @AccName +':'+ 'START:' + convert(varchar(50), getdate(), 113)
--=============================
--PERFORM MOVING MEMBERS
--=============================


--Copy custSetting data to bodb_Customer before delete
insert into DBARCCUST.bodb_Customer.dbo.custSetting_old(
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
select 	custid, 
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
from	custSetting (nolock) 
where	custid IN (	select custid from custinfo with (nolock) where roleid = 1 and recommend = @AgentID)

--Copy custSetting3rd data to bodb_Customer 
insert into DBARCCUST.bodb_Customer.dbo.custSetting3rd_old(
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
SELECT	[custid]
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
FROM	CustSetting3rd WITH (NOLOCK)
WHERE	custid IN (SELECT custid FROM custInfo WITH (NOLOCK) WHERE roleid = 1 and recommend = @AgentID)		

--Copy DBTRANS.BODB02.dbo.P2PGameSetting data to DB05.bodb_Customer.dbo.P2PGameSetting_Old
insert into DBARCCUST.bodb_Customer.dbo.P2PGameSetting_Old(
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
FROM [dbo].[P2PGameSetting]  WITH (NOLOCK)
WHERE	custid IN (SELECT custid FROM custInfo WITH (NOLOCK) WHERE roleid = 1 and recommend = @AgentID) 

--Copy DBTRANS.BODB02.dbo.P2PGroupComm data to DB05.bodb_Customer.dbo.P2PGroupComm_Old
insert into DBARCCUST.bodb_Customer.dbo.P2PGroupComm_Old(
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
FROM [dbo].[P2PGroupComm]  WITH (NOLOCK)
WHERE custid IN (SELECT custid FROM custInfo WITH (NOLOCK) WHERE roleid = 1 and recommend = @AgentID) 

--- copy DBTRANS.BODB02.dbo.CustSettingGame data to DB05.bodb_Customer.dbo.CustSettingGame_Old
INSERT INTO DBARCCUST.bodb_Customer.dbo.CustSettingGame_Old(
			CustID
			,Bettype
			,Sporttype
			,apositiontaking
			,mpositiontaking
			,spositiontaking
			,playerdiscount
			,discount
			,adiscount
			,sdiscount
			,autopositiontaking
			,isautopositiontaking
			,autompositiontaking
			,isautompositiontaking)
SELECT CustID
		,Bettype
		,Sporttype
		,apositiontaking
		,mpositiontaking
		,spositiontaking
		,playerdiscount
		,discount
		,adiscount
		,sdiscount
		,autopositiontaking
		,isautopositiontaking
		,autompositiontaking
		,isautompositiontaking
FROM [dbo].[CustSettingGame] WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @AgentID AND roleid = 1)

--- copy DBTRANS.BODB02.dbo.CustGameType data to DB05.bodb_Customer.dbo.CustGameType_Old
INSERT INTO DBARCCUST.bodb_Customer.dbo.CustGameType_Old(CustID, GameTypeID, StakeLevelList, MaxPerGameType, MinBet, MaxBet, IsDisabled)
SELECT CustID, GameTypeID, StakeLevelList, MaxPerGameType, MinBet, MaxBet, IsDisabled
FROM [dbo].CustGameType WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @AgentID AND roleid = 1)

--- copy DBTRANS.BODB02.dbo.CustVirtualRate data to DB05.bodb_Customer.dbo.CustVirtualRate_Old
INSERT INTO DBARCCUST.bodb_Customer.dbo.CustVirtualRate_Old(custid, sporttype, bettype, isLive, virtualMultiplier)
SELECT custid, sporttype, bettype, isLive, virtualMultiplier
FROM [dbo].CustVirtualRate WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @AgentID AND roleid = 1)

--- copy DBTRANS.BODB02.dbo.CustVirtualSetting data to DB05.bodb_Customer.dbo.CustVirtualSetting_Old
INSERT INTO DBARCCUST.bodb_Customer.dbo.CustVirtualSetting_Old(custid, seqNo, bitmapVirtual)
SELECT custid, seqNo, bitmapVirtual
FROM [dbo].CustVirtualSetting WITH(NOLOCK)
WHERE custid IN (SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @AgentID AND roleid = 1)

Exec Acc_ExecRep_Cust_01 @AgentID = @AgentID, @Type = 0 
----------------------------------------------------------------
print  @AccName +':'+ 'END:' + convert(varchar(50), getdate(), 113)

------------------
declare @LogSPData varchar(2000)

Select @LogSPData = '<DBA_ArchiveAccount1_UpdateMove AccName="'+ coalesce(cast(@AccName as varchar(50)),space(1))+ '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))  + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1500,
	@TrackingValue = @LogSPData	,
	@duration = @duration


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount1_UpdateMove] TO [vnteam]