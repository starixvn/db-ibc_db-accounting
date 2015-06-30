ALTER PROCEDURE [dbo].[DBA_ArchiveAccount2_UpdateMove]
	@AccName varchar(50),	
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created by: []
	Date: []
	Task: Archive unused Account in Stage 2 
	DB: DBTXN/BODB02 
	
	Revisions:
		- 20091224@Jamie: Separate 3rd CustSetting 
		- 20100107@Kiwi: Amend writing log.
		- 20100204@Jamie: Remove positiontakingallowday, positiontakingallowtime1,positiontakingallowtime2
		- 20100208@Kiwi: Remove UTN field.
		- 20100413@Kiwi: Remove custinfo.AffiliateID, customer.gender, customer.question, customer.answer, customer.transferoption fields
		- 20100511@Henry: Insert data to columns: DisableOpenTote & maxpermatch151_OT of bodb_Customer.dbo.custInfo_old
		- 20100831@Thien: remove custinfo.MaxCredit field
		- 20100912@Thien: new fields for custinfo/custinfo_old: [DisableBingo],[DisableNumber],[SyncBingo],[MaxPerMatch161],[MaxPerMatch99MP]
		- 20101019@Henry: Record execution time
		- 20101030@Henry: new fields for custinfo/custinfo_old: [MaxPerBall161]
		- 20110122@Henry: new fields for custinfo/custinfo_old: [MaxPerMatch151_AU], [MaxPerMatch152_UK], [MaxPerMatch152_AU], [MaxPerMatch153_AU], [Disable151_AU], [Disable152_UK], [Disable152_AU], [Disable153_AU]
		- 20111007@Tom: new fields for custinfo/custinfo_old: MaxtransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P.
		- 20120316@Lukas: add 2 new fields for live casino
		- 20120816@Dan: add 3 new fields for for VS
		- 20120821@Elodie: add Abnormal fields
		- 20121004@Johnson: add double comm losing status
		- 20121005@Thien: change connection of bodb_Customer to DB05
		- 20121015@Dan: add fields for LCS-WinLimit (isAutoResetLiveCasino,MaxWinLiveCasino)
		- 20121204@Scott: add fields for virtual tennis (maxpermatch186)
		- 20130121@Johnson: change linked server from DB05 to DBARCCUST
		- 20130808@Elodie: Splitting DBTXN into DBCUST (Call Acc_ExecRep_Cust_01 instead of Acc_ExecRep_01, call bettrans by link database)
		- 20140208@Thien: Revise the field list of custinfo_old table 

	Note: Review the SP again once executing as maybe new fields were added to customer or custinfo table.
*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

Declare @roleid int, @AgentID int, @Now datetime, @Enabled bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid <> 2 or @Enabled = 1
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END


print  @AccName +':'+ 'Start:' + convert(varchar(50), getdate(), 113)

--==========================================================
--CREATING TEMP TABLES
--==========================================================

CREATE TABLE #Member 
(
	custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int,
	membername varchar(50), agentname varchar(50), mastername varchar(50), supername varchar(50), 
	transCount int default 0
)
		
IF @roleid = 2
BEGIN
	INSERT INTO #Member (custid, recommend, mrecommend, srecommend, 
						membername, agentname, mastername, supername)
	SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, 
			c.username, ag.username, mag.username, sag.username
	FROM custinfo c (nolock)
		inner join custinfo ag (nolock) on c.recommend = ag.custid
		inner join custinfo mag (nolock) on c.mrecommend = mag.custid
		inner join custinfo sag (nolock) on c.srecommend = sag.custid
	WHERE  c.recommend = @AgentID AND c.roleid = 1
	
END
		
--==========================================================
--CHECK TransCOUNT FIRST, MAKE SURE ALL BALANCE ARE CLEARED
--==========================================================

-- CHECK MEMBER BALANCE	
Update #Member set transCount = b.transCount
from #Member
	inner join (
		Select custid, count(*) as transCount
		From bodb02.dbo.bettrans with (NOLOCK)
		group by custid
		) b on #Member.custid = b.custid	

--select * from #Member
if exists(select 1 from #Member where transCount > 0)
BEGIN
	print @AccName +':'+ 'Error: Unlcleared member''s TransCOUNT exist!'
	Select @ErrMsg = @AccName +':'+ 'Unlcleared member''s TransCOUNT exist!', @ErrCode = 101
	return
END	

print @AccName +':'+ 'Check members TransCOUNT done:' + convert(varchar(50), getdate(), 113)	
	

--=============================
--PERFORM MOVING MEMBERS
--=============================

select @Now = current_timestamp

--Copy members'info to bodb_Customer before delete
insert into DBARCCUST.bodb_Customer.dbo.customer_old(
	   [custid],[firstname],[lastname],[address] ,[postal],[city]
      ,[state] ,[country]  ,[phone]   ,[mobilephone] ,[fax]
      ,[email] ,[birthday] ,[refcode1],[refcode2],[remark]
      ,[creatdate],[creator],[username],[currency],[userpwd]
      ,[lastlogged],[pwdexpiry],[roleid],[mrecommend],[recommend]
      ,[ugroup],[logincount],[on_sessionid],[site],[iplogin]
      ,[important],[srecommend],[username2]
)
select [custid],[firstname],[lastname],[address] ,[postal],[city]
      ,[state] ,[country]  ,[phone]   ,[mobilephone] ,[fax]
      ,[email] ,[birthday] ,[refcode1],[refcode2],[remark]
      ,[creatdate],[creator],[username],[currency],[userpwd]
      ,[lastlogged],[pwdexpiry],[roleid],[mrecommend],[recommend]
      ,[ugroup],[logincount],[on_sessionid],[site],[iplogin]
      ,[important],[srecommend],[username2]
from	customer (nolock) where custid IN (select custid from #Member with (nolock))
IF @@Error<>0
BEGIN
	Select	@ErrMsg = 'Failed INSERT from CUSTOMER table to CUSTOMER_OLD table', 
			@ErrCode = 102
	return
END 

insert into DBARCCUST.bodb_Customer.dbo.custinfo_old(
	   [ArchiveDate],
	  username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, 
                      MatchLimit, VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, 
                      maxpermatch12, maxpermatch99, [Enabled], danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino, 
                      SyncCasino, danger2, danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT, DisableBingo, DisableNumber, SyncBingo, 
                      MaxPerMatch161, MaxPerMatch99MP, MaxPerBall161, MaxPerMatch151_AU, MaxPerMatch152_UK, MaxPerMatch152_AU, MaxPerMatch153_AU, 
                      Disable151_AU, Disable152_UK, Disable152_AU, Disable153_AU, MaxtransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P, DisableLiveCasino, 
                      SyncLiveCasino, DisableVirtualSports, HideVirtualSports, maxpermatch180, Abnormal, DoubleCommLosing, isAutoResetLiveCasino, 
                      MaxWinLiveCasino, maxpermatch182, DisableCasinoBonus, maxpermatch184, DisableHRFixedOdds, maxpermatch154, autosuspend2, 
                      maxpermatch183, maxpermatch185  
)
select	@Now, 
	   username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, 
                      MatchLimit, VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, 
                      maxpermatch12, maxpermatch99, [Enabled], danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino, 
                      SyncCasino, danger2, danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT, DisableBingo, DisableNumber, SyncBingo, 
                      MaxPerMatch161, MaxPerMatch99MP, MaxPerBall161, MaxPerMatch151_AU, MaxPerMatch152_UK, MaxPerMatch152_AU, MaxPerMatch153_AU, 
                      Disable151_AU, Disable152_UK, Disable152_AU, Disable153_AU, MaxtransferP2P, IsAutoResetP2P, DisableP2P, DisableFunP2P, DisableLiveCasino, 
                      SyncLiveCasino, DisableVirtualSports, HideVirtualSports, maxpermatch180, Abnormal, DoubleCommLosing, isAutoResetLiveCasino, 
                      MaxWinLiveCasino, maxpermatch182, DisableCasinoBonus, maxpermatch184, DisableHRFixedOdds, maxpermatch154, autosuspend2, 
                      maxpermatch183, maxpermatch185     
from	custinfo (nolock) where custid IN (select custid from #Member with (nolock))
IF @@Error<>0
BEGIN
	Select	@ErrMsg = 'Failed INSERT from CUSTINFO table to CUSTINFO_OLD table', 
			@ErrCode = 103
	return
END 
Exec Acc_ExecRep_Cust_01 @AgentID = @AgentID, @Type = 1 

print @AccName +':'+ 'Move members done:' + convert(varchar(50), getdate(), 113)	
----------------------------------------------------------------
DROP TABLE #Member
--------------
declare @LogSPData varchar(2000)

Select @LogSPData = '<DBA_ArchiveAccount2_UpdateMove AccName="'+ coalesce(cast(@AccName as varchar(50)),space(1))+ '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))  + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1501,
	@TrackingValue = @LogSPData,
	@duration = @duration


GO
GRANT EXECUTE ON [dbo].[DBA_ArchiveAccount2_UpdateMove] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DBA_ArchiveAccount2_UpdateMove] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount2_UpdateMove] TO [vnteam] AS [dbo]