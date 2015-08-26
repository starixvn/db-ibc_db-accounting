ALTER PROCEDURE [dbo].[NAP_BettransSpecialDelBetID_Del]  
 @strTransID  VARCHAR(MAX) = '',  
 @CustID   int = 0,  
 @username  varchar(30),  
 @password  varchar(50),  
 @UserID   int = 0, --custid of Admin,  
 @IP    varchar(15) = '',  
 @reason   nvarchar(500)= '',  
 @ErrCode  int = 0 OUTPUT,  
 @ErrMsg   nvarchar(200) = '' OUTPUT  
AS  
/* Created by: Jamie  
 Task:  VOID BY BET ID (Running & Settled tickets)  
 DB: DBTXN/bodb02  
 Original:   
   
 Revisions:  
  - 20141125@Kathy: Add betid column [Redmine:##26489]  
  - 20150402@Dominic: Add new 60 bettypes [Redmine:#27214]  
  - 20150606@Kathy: Migrate custDB to new server DBCust(Get credit from DBCust.CustDB) [Redmine:#36216]   
  - 20150615@Dominic: BetTrade Integration  [Redmine:#36964]  
  - 20150623@Dominic: Add Metric Gaming Super Live [Redmine:##38200]  
 Param's Explanation:   
*/  
BEGIN   
 SET NOCOUNT ON  
  
 -- As confirmed by BA, No need to check permission inside SP  
 ----Check permission for account site  
 --EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[DeleteBets]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output  
 --If @ErrCode <> 0  
 -- RETURN  
  
 DECLARE @LogData  NVARCHAR(500)   
   ,@isITAdmin  BIT  
  
 SELECT @isITAdmin  = 0   
  
 If NOT EXISTS (select 1 from CustDB.dbo.customer c with (nolock) where userpwd = @password and custid = @userid and roleid >= 5)  
 BEGIN  
  SELECT  @ErrMsg = 'Sorry. You cannot process void bets due to either wrong password or insufficient permission!'  
    ,@ErrCode = 101  
  
  SELECT @LogData = 'Try to delete transaction for custid: ' + cast(@UserID AS VARCHAR(10)) + ' betlist: ' + cast(@strtransid AS VARCHAR(8000)) + ' - Username: ' + @username + ' - reason: ' + @reason  
  
  EXEC WriteLog_UserLog @UserID = @UserID ,@Doing = @LogData  
  RETURN  
 END  
  
 CREATE TABLE #BeforeUpd (  
   custid   INT,  
   balance   MONEY)  
    
 CREATE TABLE #AfterUpd(  
    custid   INT,  
    balance   MONEY)  
      
 DECLARE @tmpListTransID TABLE (  
   TransID  BIGINT  
  ,GroupTransID BIGINT  
  ,MatchID  INT  
  ,Bettype  INT  
  ,betid   BIGINT  
  ,stake   MONEY  
  ,odds   SMALLMONEY  
  ,Refno   BIGINT  
  ,Betfrom  NVARCHAR(10)  
  ,StatusID  TINYINT  
  ,KeyID   INT   
  ,TicketType  TINYINT -- 1: from bettrans, 2:from translog  
 )  
  
 INSERT INTO @tmpListTransID(  
   TransID  
  ,GroupTransID  
  ,MatchID  
  ,Bettype  
  ,betid  
  ,stake  
  ,odds  
  ,Refno  
  ,Betfrom  
  ,StatusID  
  ,KeyID  
  ,TicketType  
 )  
 SELECT  TransID  TransID  
   ,TransID  GroupTransID  
   ,MatchID  
   ,Bettype  
   ,betid  
   ,stake  
   ,odds  
   ,Refno  
   ,Betfrom  
   ,StatusID  
   ,CASE WHEN Bettype = 9 THEN -1 -- isCalculatingParlay in SystemSettings OR 1 (Single match)  
        WHEN Bettype = 10 THEN 2    -- Outright   
        WHEN Bettype IN (801,803,804,805,806) THEN 3  
        ELSE 1 END  -- SB, NG, LiveCS   
   ,1  
 FROM Bettrans WITH (NOLOCK)  
 WHERE TransID  IN (SELECT CONVERT(BIGINT,Val) FROM dbo.strSplit(@strTransID,','))  
   AND StatusID NOT IN (101, 102) -- REJECT, VOID 
   AND Bettype NOT IN (801,803,804,805,806)
 UNION ALL
  SELECT  Refno TransID  
   ,Refno GroupTransID  
   ,MatchID  
   ,Bettype  
   ,betid  
   ,stake  
   ,odds  
   ,Refno  
   ,Betfrom  
   ,StatusID  
   ,CASE WHEN Bettype = 9 THEN -1 -- isCalculatingParlay in SystemSettings OR 1 (Single match)  
        WHEN Bettype = 10 THEN 2    -- Outright   
        WHEN Bettype IN (801,803,804,805,806) THEN 3  
        ELSE 1 END  -- SB, NG, LiveCS   
   ,1  
 FROM Bettrans WITH (NOLOCK)  
 WHERE Refno IN (SELECT CONVERT(BIGINT,Val) FROM dbo.strSplit(@strTransID,','))  
   AND StatusID NOT IN (101, 102) -- REJECT, VOID 
   AND Bettype  IN (801,803,804,805,806) 
 UNION ALL  
 --Get data from Translog for Metric Gaming Super Live  
 SELECT  translogid TransID, translogid GroupTransID  
   ,eventID matchID  
   ,b.GameID  
   ,0 betid  
   ,b.stake  
   ,0 odds  
   ,translogid Refno  
   ,b.Betfrom  
   ,b.StatusID  
   ,3  
   ,2  
 FROM translog b WITH (NOLOCK)  
  LEFT JOIN bettrans bs WITH(NOLOCK) ON b.gameid = bs.bettype AND bs.matchid = b.eventid AND bs.custid = b.Custid AND b.translogid = bs.refno  
 WHERE translogid IN (SELECT CONVERT(BIGINT,Val) FROM dbo.strSplit(@strTransID,','))  
   AND b.StatusID NOT IN (101, 102) -- REJECT, VOID  
   AND b.GameID IN (801,803,804,805,806) AND bs.refno IS NULL  
     
 --Update 901.betid=main.bettype  
 UPDATE main  
 SET main.betid = b.bettype, main.odds = b.odds, main.stake = b.stake, main.GroupTransID = b.transid  
 FROM @tmpListTransID main  
 INNER JOIN Bettrans b WITH (NOLOCK) ON b.transid = main.refno AND b.matchid = main.MatchID  
 WHERE main.bettype = 901  
  
 IF EXISTS(SELECT TOP 1 1 FROM @tmpListTransID WHERE Bettype = 9 AND StatusID BETWEEN 111 AND 113)  -- DRAW, WON, LOSE   
 BEGIN  
  DELETE FROM @tmpListTransID WHERE Bettype = 9 AND StatusID BETWEEN 111 AND 113 -- Not allowed to delete settled(DRAW, WON, LOSE ) Mix Parlay   
 END  
  
 IF EXISTS(SELECT TOP 1 1 FROM @tmpListTransID WHERE Bettype BETWEEN 1101 AND 1199 AND StatusID BETWEEN 0 AND 1)  
 BEGIN  
  DELETE FROM @tmpListTransID WHERE Bettype BETWEEN 1101 AND 1199 AND StatusID BETWEEN 0 AND 1 -- Not allowed to settle the running Live CS bet   
 END  
  
 DECLARE @Recommend   INT  
   ,@MRecommend  INT  
   ,@Srecommend  INT  
   ,@Site    VARCHAR(10)  
   ,@Username2   VARCHAR(30)  
   ,@isExistMatch  BIT  
   ,@isExistParlay  BIT  
   ,@isExistOutright BIT  
   ,@isCustDeposit  BIT  
   ,@CustUsername  VARCHAR(30)  
   ,@AgUsername  VARCHAR(30)  
   ,@MAgUsername  VARCHAR(30)  
   ,@SAgUsername  VARCHAR(30)  
   ,@EmailGroup  VARCHAR(30)  
   ,@winlostdate  DATETIME  
   ,@currency   INT  
  
 DECLARE @ErrorTransID  TABLE(transid BIGINT PRIMARY KEY)  
   
 SELECT @winlostdate = MIN(winlostdate)  
   ,@CustID  = MIN(CustID)  
   ,@isExistMatch = MAX(CASE WHEN Bettype NOT IN (9,10) THEN 1 ELSE 0 END)  
   ,@isExistParlay = MAX(CASE WHEN Bettype = 9 THEN 1 ELSE 0 END)  
   ,@isExistOutright = MAX(CASE WHEN Bettype = 10 THEN 1 ELSE 0 END)  
 FROM (  
   SELECT winlostdate,CustID,winlost,actual_stake,playercomm,Bettype  
   FROM Bettrans WITH (NOLOCK)  
   WHERE TransID IN (SELECT TransID FROM @tmpListTransID WHERE TicketType = 1 AND Bettype NOT IN (901,902,903)) 
		AND Bettype NOT IN (801,803,804,805,806)
   UNION ALL
   SELECT winlostdate,CustID,winlost,actual_stake,playercomm,Bettype  
   FROM Bettrans WITH (NOLOCK)  
   WHERE Refno IN (SELECT TransID FROM @tmpListTransID WHERE TicketType = 1 AND Bettype NOT IN (901,902,903)) 
      AND Bettype IN (801,803,804,805,806)
   UNION ALL  
   SELECT winlostdate,CustID,0 winlost,actual_stake,0 playercomm,GameID Bettype  
   FROM translog WITH (NOLOCK)  
   WHERE translogid IN (SELECT TransID FROM @tmpListTransID WHERE TicketType = 2)  
    AND GameID IN (801,803,804,805,806)  
     
  ) tmp   
     
  
 SELECT  @Username2  = Username2  
   ,@CustUsername = username  
   ,@Recommend  = recommend  
   ,@MRecommend = mrecommend  
   ,@Srecommend = srecommend  
 FROM CustDB.dbo.Customer WITH (NOLOCK)  
 WHERE CustID = @CustID  
  
 --Check settled Date  
 EXEC dbo.Acc_CheckSettledDate @winlostdate = @winlostdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT  
 If @ErrCode <> 0  
  RETURN  
   
 --- CHECKING SETTLEMENT PROCESS IN PROGRESS OR NOT ?????  
 DECLARE @UpdSystemSettings TINYINT = 0  
 IF(@isExistParlay = 1)  
 BEGIN  
  IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')  
  BEGIN  
   SELECT @ErrCode = 201  
   SELECT @ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'  
   RETURN  
  END  
  ELSE   
  BEGIN  
   UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)  
   SET VValue = '1'  
   WHERE VName = 'isCalculatingParlay' AND VValue = 0  
     
   SELECT @UpdSystemSettings = @@ROWCOUNT  
  END   
 END  
  
 DECLARE @MatchId     INT,  
         @KeyId       TINYINT,  
         @Remark   VARCHAR(500)  
           
 DECLARE @LockTbl TABLE(KeyID INT, KeyValue MONEY, IsLocked BIT)  
   
 INSERT @LockTbl(KeyID, KeyValue, IsLocked)   
 SELECT DISTINCT t.KeyID,  
      t.matchid,  
      0  
 FROM   @tmpListTransID t   
 WHERE Bettype <> 9  
   
 WHILE (1 = 1)  
 BEGIN  
     SELECT TOP 1 @KeyId = t.KeyID,  
            @MatchId = t.matchid  
     FROM   @tmpListTransID t  
     WHERE  t.Bettype NOT IN (9,901,902,903)  AND t.matchid NOT IN (SELECT v.KeyValue  
                              FROM   dbo.TempVariableNumber v with(NOLOCK)  
                              WHERE  v.KeyID = t.KeyID)  
       
     IF @@rowcount = 0  
         BREAK  
       
     INSERT INTO dbo.TempVariableNumber  
       (  
         KeyID,  
         KeyValue  
       )  
     VALUES  
       (  
         @KeyId,  
      @MatchId  
       )    
     IF (@@Error = 0)  
     BEGIN  
   BEGIN TRY   
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
      @UserID = @UserID,  
      @Matchid = @matchid,  
      @KeyID = @KeyID,  
      @ActionID = 0,  
      @Remark = 'ADD SUCCESS SPName= NAP_BettransSpecialDelBetID_Del'  
   END TRY       
   BEGIN CATCH  
       SELECT @Remark = 'ADD SUCCESS SPName=NAP_BettransSpecialDelBetID_Del ErrMsg='   
           + LEFT(ERROR_MESSAGE(), 400)  
         
       EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
         @UserID = @UserID,  
         @Matchid = @matchid,  
         @KeyID = @KeyID,  
         @ActionID = 0,  
         @Remark = @Remark   
   END CATCH  
     
   UPDATE @LockTbl  
   SET IsLocked = 1  
   WHERE KeyID = @KeyId AND KeyValue = @MatchId  
     END  
     ELSE   
     BEGIN  
   BEGIN TRY   
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
      @UserID = @UserID,  
      @Matchid = @matchid,  
      @KeyID = @KeyID,  
      @ActionID = 0,  
      @Remark = 'ADD FAIL SPName= NAP_BettransSpecialDelBetID_Del'  
   END TRY       
   BEGIN CATCH  
       SELECT @Remark = 'ADD FAIL SPName=NAP_BettransSpecialDelBetID_Del ErrMsg='   
           + LEFT(ERROR_MESSAGE(), 400)  
         
       EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
         @UserID = @UserID,  
         @Matchid = @matchid,  
         @KeyID = @KeyID,  
         @ActionID = 0,  
         @Remark = @Remark   
   END CATCH  
     
   DELETE main  
   FROM dbo.TempVariableNumber main  
   INNER JOIN @LockTbl lk ON lk.KeyID = main.KeyID AND lk.KeyValue = main.KeyValue  
   WHERE lk.IsLocked = 1  
     
   IF @isExistParlay = 1 AND @UpdSystemSettings > 0  
   BEGIN  
    UPDATE SystemSettings WITH (ROWLOCK, UPDLOCK)  
    SET VValue = '0'  
    WHERE VName = 'isCalculatingParlay'  
   END  
     
      SELECT @ErrCode = 100,  
             @ErrMsg =   
             'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'  
      RETURN  
     END  
 END  
   
 IF EXISTS(SELECT TOP 1 1 FROM @LockTbl WHERE IsLocked = 0)  
 BEGIN  
  SELECT TOP 1 @matchid = KeyValue, @KeyID = KeyID  
  FROM @LockTbl WHERE IsLocked = 0  
    
  BEGIN TRY   
   EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
     @UserID = @UserID,  
     @Matchid = @matchid,  
     @KeyID = @KeyID,  
     @ActionID = 0,  
     @Remark = 'ADD FAIL SPName= NAP_BettransRecoverBet'  
  END TRY       
  BEGIN CATCH  
      SELECT @Remark = 'ADD FAIL SPName=NAP_BettransRecoverBet ErrMsg='   
          + LEFT(ERROR_MESSAGE(), 400)  
  END CATCH  
    
  DELETE main  
  FROM dbo.TempVariableNumber main  
  INNER JOIN @LockTbl lk ON lk.KeyID = main.KeyID AND lk.KeyValue = main.KeyValue  
  WHERE lk.IsLocked = 1  
    
  IF @isExistParlay = 1 AND @UpdSystemSettings > 0  
  BEGIN  
   UPDATE SystemSettings WITH (ROWLOCK, UPDLOCK)  
   SET VValue = '0'  
   WHERE VName = 'isCalculatingParlay'  
  END  
    
  SELECT @ErrCode = 100,  
             @ErrMsg =   
             'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'  
     RETURN  
 END  
  
 -- CHECK IT GROUP or NOT ?   
 EXEC DBPOLICY.bodb02.dbo.Acc_Con_GroupInfoSel   
   @GroupID = 1        -- 'IT' GROUP   
  ,@UserID = @UserID  
  ,@ShowInternalGroup = 0  
  ,@System = 'ACCOUNTING'  
 IF @@ROWCOUNT <> 0   
 BEGIN  
  SELECT @isITAdmin = 1   
 END  
  
 SELECT @Site = Site  
   ,@AgUsername = username  
   ,@currency  = Currency   
 FROM CustDB.dbo.Customer WITH (NOLOCK)  
 WHERE CustID = @Recommend  
   
 SELECT @MAgUsername = Username   
 FROM CustDB.dbo.CustInfo WITH (NOLOCK)  
 WHERE CustID = @MRecommend  
  
 SELECT @SAgUsername = Username   
 FROM CustDB.dbo.CustInfo WITH (NOLOCK)  
 WHERE CustID = @SRecommend  
  
 IF (EXISTS(SELECT TOP 1 1 from CustDB.dbo.Dep_CustSuper WITH (NOLOCK) WHERE CustID =@SRecommend ))  
 BEGIN  
  SELECT @isCustDeposit = 1   
 END  
  
 SELECT @EmailGroup = CASE WHEN @CustUsername = '12EU' THEN '12EU'  
        WHEN @isCustDeposit = 1 THEN 'Deposit'   
        WHEN @Recommend = 11196380 THEN 'Foobet'  -- FB  
        WHEN @CustID IN (1077687, 2331, 115770, 15523642) THEN 'Betfair'  -- Betfair: BFOS, BF, ITibc102, BF3  
        WHEN @Recommend = 13423967 THEN 'OneExchange'  --1E  
        ELSE '' END   
 -- SINGLE BET   
 UPDATE odds  
 SET hometotal = hometotal - (CASE WHEN b.betteam = 'h' THEN CASE WHEN abs(b.odds) > 1 THEN b.stake * e.actualrate * abs(b.odds) * (1 - b.tpositiontaking)  
                  ELSE b.stake * e.actualrate * (1 - b.tpositiontaking) END  
           ELSE 0 END )  
  ,awaytotal = awaytotal - (CASE WHEN b.betteam = 'a' THEN CASE WHEN abs(b.odds) > 1 THEN b.stake * e.actualrate * abs(b.odds) * (1 - b.tpositiontaking)  
                  ELSE b.stake * e.actualrate * (1 - b.tpositiontaking) END  
            ELSE 0 END)  
 FROM odds o WITH (ROWLOCK,UPDLOCK)  
  INNER JOIN bettrans b WITH (NOLOCK) ON o.oddsid = b.oddsid  
  INNER JOIN CustDB.dbo.customer c WITH (NOLOCK) ON c.custid = b.custid  
  INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid  
 WHERE b.transid IN (  
    SELECT TransID  
    FROM @tmpListTransID  
    WHERE Bettype <> 9   
      AND Bettype NOT IN (801,803,804,805,806,901,902,903) --Metric Gaming Super Live / BetTrade subtickets  
   )  
   
 --Update if there are any concurrency problems for MGSL - start  
 UPDATE main  
 SET main.TicketType = 1,  
  main.TransID = bs.transid,  
  main.StatusID = bs.StatusID  
 FROM @tmpListTransID  main  
  INNER JOIN bettrans bs WITH(NOLOCK) ON main.Refno = bs.refno AND main.bettype = bs.bettype  
 WHERE main.bettype IN (801,803,804,805,806)  
 --Update if there are any concurrency problems for MGSL - end  
  
  
 -- Get Upline info   
  
 SELECT  @CustID   AS CustID   
   ,@CustUsername  AS CustUsername  
   ,@Username2   AS Username2  
   ,@AgUsername  AS AgUsername  
   ,@Recommend   AS Recommend  
   ,@MAgUsername  AS MAgUsername  
   ,@MRecommend  AS Mrecommend  
   ,@SAgUsername  AS SAgUsername  
   ,@Srecommend  AS SRecommend   
   ,@currency   AS Currency   
   ,@Site    AS [Site]  
   ,@EmailGroup  AS EmailGroup   
   ,@isITAdmin   AS isITAdmin   
  
    
 --- BETS: return all additional information for mailing  
 SELECT m.homeid,  
   m.awayid,  
   m.matchcode,  
   m.eventdate,  
   m.leagueid,  
   GETDATE() AS DATETIME,  
   isnull(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,  
   showtime AS GameEvent,  
   b.bettype,  
   tpl.odds,    
   b.OddsType,   
   b.transdate,  
   b.bettype,  
   CASE WHEN b.bettype IN (801,803,804,805,806) THEN b.refno ELSE b.transid END transid,  
   b.refno,  
   b.betteam,  
   b.betcheck,  
   b.hdp1,  
   b.hdp2,  
   b.betfrom,  
   b.livehomescore,  
   b.liveawayscore,  
   b.liveindicator,  
   cr.username creator,  
   usr.username username,
   CASE WHEN b.bettype = 901 THEN tpl.stake ELSE b.stake END stake,       
   CASE WHEN b.bettype = 901 THEN 'SOLD' ELSE b.status END [status],  
   b.winlost - actual_stake as winlost,  
   b.playercomm as comm,        
   b.currency,  
   tpl.betid,  
   b.transdesc,  
   tpl.grouptransid  
 FROM bettrans b WITH (NOLOCK)  
   INNER JOIN @tmpListTransID tpl ON tpl.transid = b.transid  
   INNER JOIN Match m WITH (NOLOCK) ON b.matchID = m.matchid  
   INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator  
   INNER JOIN CustDB.dbo.customer usr WITH (NOLOCK) ON usr.custid = b.custid 
 WHERE CASE WHEN b.bettype IN (801,803,804,805,806) THEN b.refno ELSE b.transid END IN (SELECT CASE WHEN bettype IN (801,803,804,805,806) THEN refno ELSE transid END FROM @tmpListTransID WHERE bettype NOT IN (10,9) AND TicketType=1)  
   AND @isExistMatch = 1   
 UNION ALL  
 -- Metric Gaming Super Live  
 SELECT m.homeid,  
   m.awayid,  
   m.matchcode,  
   m.eventdate,  
   m.leagueid,  
   GETDATE() AS DATETIME,  
   isnull(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,  
   showtime AS GameEvent,  
   b.GameID,  
   b.odds,    
   b.custom1 OddsType,   
   b.transdate,  
   b.GameID,  
   b.translogID transid,  
   b.translogID refno,  
   NULL betteam,  
   NULL betcheck,  
   0 hdp1,  
   0 hdp2,  
   b.betfrom,  
   NULL livehomescore,  
   NULL liveawayscore,  
   NULL liveindicator,  
   cr.username creator,  
   usr.username username,  
   b.stake,       
   b.status,  
   - actual_stake as winlost,  
   0 comm,        
   b.currency,  
   NULL betid,  
   b.transdesc,  
   b.translogID grouptransid  
 FROM translog b WITH (NOLOCK)  
   INNER JOIN Match m WITH (NOLOCK) ON b.EventID = m.matchid  
   INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator  
   INNER JOIN CustDB.dbo.customer usr WITH (NOLOCK) ON usr.custid = b.custid 
 WHERE b.translogid IN (SELECT TransID FROM @tmpListTransID WHERE TicketType=2)  
   AND @isExistMatch = 1  
 UNION ALL   
 SELECT   
   0 AS homeid,  
   0 AS awayid,  
   '' AS matchcode,  
   '' AS eventdate,  
   0 AS leagueid,  
   GETDATE() AS DATETIME,  
   CONVERT(BIT,0) AS IsNeutral,  
   ''  AS GameEvent,  
   b.bettype,  
   b.odds,    
   b.OddsType,   
   b.transdate,  
   b.bettype,  
   b.transid,  
   b.refno,  
   '' AS betteam,  
   '' AS betcheck,  
   0 AS hdp1,  
   0 AS hdp2,  
   '' AS betfrom,  
   0 AS livehomescore,  
   0 AS liveawayscore,  
   0 AS liveindicator,  
   cr.username creator,  
   usr.username username,  
   b.stake,       
   b.status,  
   b.winlost - actual_stake as winlost,  
   b.playercomm as comm,        
   b.currency,  
   b.betid,  
   b.transdesc,  
   b.transid grouptransid  
 FROM bettrans b WITH(NOLOCK)   
   INNER JOIN CustDB.dbo.customer AS cr with (NOLOCK) ON cr.custid = b.creator  
   INNER JOIN CustDB.dbo.customer usr WITH (NOLOCK) ON usr.custid = b.custid 
 WHERE b.transid IN (SELECT TransID FROM @tmpListTransID WHERE bettype = 9)  
   AND @isExistParlay = 1   
 UNION ALL   
 SELECT m.teamid AS homeid,  
   0 AS awayid,  
   m.matchcode,  
   m.eventdate,  
   m.leagueid,  
   GETDATE() AS DATETIME,  
   CONVERT(BIT,0) AS IsNeutral,  
   '' AS GameEvent,    -- N/A   
   b.bettype,  
   b.odds,    
   b.OddsType,   
   b.transdate,  
   b.bettype,  
   b.transid,  
   b.refno,  
   b.betteam,  
   b.betcheck,  
   b.hdp1,  
   b.hdp2,  
   b.betfrom,  
   b.livehomescore,  
   b.liveawayscore,  
   b.liveindicator,  
   cr.username creator,  
   usr.username username,  
   b.stake,       
   b.status,  
   b.winlost - actual_stake as winlost,  
   b.playercomm as comm,        
   b.currency,  
   b.betid,  
   b.transdesc,  
   b.transid grouptransid  
 FROM  
   bettrans b WITH (NOLOCK)  
   INNER JOIN Outright m WITH (NOLOCK) ON b.matchID = m.orid  
   INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator  
   INNER JOIN CustDB.dbo.customer usr WITH (NOLOCK) ON usr.custid = b.custid 
 WHERE b.transid IN (SELECT TransID FROM @tmpListTransID WHERE bettype = 10)  
   AND @isExistOutright = 1   
 ORDER BY grouptransid,transid  
   
 --Email Bettrade  
 SELECT m.homeid,  
   m.awayid,  
   m.matchcode,  
   m.eventdate,  
   m.leagueid,  
   GETDATE() AS DATETIME,  
   isnull(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,  
   showtime AS GameEvent,  
   b.bettype,  
   tpl.odds,    
   b.OddsType,   
   b.transdate,  
   b.bettype,  
   b.transid,  
   b.refno,  
   b.betteam,  
   b.betcheck,  
   b.hdp1,  
   b.hdp2,  
   b.betfrom,  
   b.livehomescore,  
   b.liveawayscore,  
   b.liveindicator,  
   cr.username creator,  
   c.username ,  
   CASE WHEN b.bettype = 901 THEN tpl.stake ELSE b.stake END stake,       
   CASE WHEN b.bettype = 901 THEN 'SOLD' ELSE b.status END [status],  
   b.winlost - b.actual_stake as winlost,  
   b.playercomm as comm,        
   b.currency,  
   tpl.betid,  
   b.transdesc,  
   tpl.grouptransid  
 FROM   
   @tmpListTransID tpl   
   INNER JOIN @tmpListTransID tpl2 ON tpl2.grouptransid = tpl.grouptransid AND tpl2.transid <> tpl.transid  
   INNER JOIN bettrans b2 WITH (NOLOCK) ON tpl.transid = b2.transid  
   INNER JOIN bettrans b WITH (NOLOCK) ON tpl2.transid = b.transid  
   INNER JOIN Match m WITH (NOLOCK) ON b.matchID = m.matchid  
   INNER JOIN CustDB.dbo.custinfo c2 WITH (NOLOCK) ON c2.custid = b2.custid  
   INNER JOIN CustDB.dbo.custinfo c WITH (NOLOCK) ON c.custid = b.custid  
   INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator   
 WHERE c2.username like '%BetTrade%' OR c.username like '%BetTrade%'  
 ORDER BY tpl.grouptransid,b.transid  
     
 --check for live casino  
 IF (@isExistMatch = 1 AND EXISTS(SELECT TOP 1 1 FROM @tmpListTransID WHERE Bettype BETWEEN 1101 AND 1199))  
 BEGIN    
  SELECT   t.TransID   
    ,bg.odds  
    ,bg.stake  
    ,bg.STATUS  
    ,bg.bettype  
    ,bg.betteam  
    ,bg.refno  
  FROM bettransG bg WITH (NOLOCK)  
    INNER JOIN @tmpListTransID t ON bg.refno = t.Refno   
  WHERE t.Bettype  BETWEEN 1101 AND 1199  
 END  
 ELSE --- Get structure for web   
 BEGIN  
  SELECT  0 AS TransID   
    ,0 AS Odds  
    ,0 AS Stake  
    ,NULL AS Status   
    ,0 AS Bettype  
    ,NULL AS betteam   
    ,0 AS refno  
 END  
  
 --*****MGSL PROCESS - START  
  --Insert ticket of MGSL in translog: 801,803,804,805,806  
  INSERT INTO [bodb02].[dbo].[bettrans]  
      ([custid]  
      ,[transdate]  
      ,[oddsid]  
      ,[hdp1]  
      ,[hdp2]  
      ,[odds]  
      ,[stake]  
      ,[status]  
      ,[winlost]  
      ,[awinlost]  
      ,[mwinlost]  
      ,[playercomm]  
      ,[comm]  
      ,[acomm]  
      ,[apositiontaking]  
      ,[mpositiontaking]  
      ,[tpositiontaking]  
      ,[playerdiscount]  
      ,[discount]  
      ,[adiscount]  
      ,[livehomescore]  
      ,[liveawayscore]  
      ,[liveindicator]  
      ,[betteam]  
      ,[creator]  
      ,[refno]  
      ,[comstatus]  
      ,[winlostdate]  
      ,[betfrom]  
      ,[betcheck]  
      ,[checktime]  
      ,[oddsspread]  
      ,[actualrate]  
      ,[matchid]  
      ,[recommend]  
      ,[mrecommend]  
      ,[ruben]  
      ,[betid]  
      ,[statuswinlost]  
      ,[modds]  
      ,[bettype]  
      ,[betdaqid]  
      ,[actual_stake]  
      ,[currency]  
      ,[ip]  
      ,[transdesc]  
      ,[sdiscount]  
      ,[scomm]  
      ,[spositiontaking]  
      ,[swinlost]  
      ,[srecommend]  
      ,[Username]  
      ,[CurrencyName]  
      ,[virtualrate]  
      ,[oddstype]  
      ,[statusID]  
      ,[currency2]  
      ,[balance]  
      ,[SecAcceptFlag]  
      ,[transid2]  
      ,[RecommDate])  
  SELECT b.[custid]  
      ,b.[transdate]  
      ,0 [oddsid]  
      ,0 [hdp1]  
      ,0 [hdp2]  
      ,b.[odds]  
      ,b.[stake]  
      ,b.[status]  
      ,0 [winlost]  
      ,0 [awinlost]  
      ,0 [mwinlost]  
      ,0 [playercomm]  
      ,0 [comm]  
      ,0 [acomm]  
      ,b.[apositiontaking]  
      ,b.[mpositiontaking]  
      ,b.[tpositiontaking]  
      ,b.[playerdiscount]  
      ,b.[discount]  
      ,b.[adiscount]  
      ,0 [livehomescore]  
      ,0 [liveawayscore]  
      ,b.[liveindicator]  
      ,SUBSTRING(b.[transdesc],11,CHARINDEX(';BettypeTime',b.[transdesc],0) - 11) [betteam]  
      ,b.[creator]  
      ,b.translogid [refno]  
      ,b.custom2 [comstatus]  
      ,b.[winlostdate]  
      ,b.[betfrom]  
      ,b.transdate [betcheck]  
      ,NULL [checktime]  
      ,0 [oddsspread]  
      ,b.[actualrate]  
      ,b.EventID  
      ,b.[recommend]  
      ,b.[mrecommend]  
      ,1 [ruben]  
      ,CASE WHEN ISNULL(b.custom3,'') = '' THEN NULL ELSE CAST(b.custom3 AS BIGINT) END [betid]  
      ,NULL [statuswinlost]  
      ,0 [modds]  
      ,b.GameID [bettype]  
      ,NULL [betdaqid]  
      ,b.[actual_stake]  
      ,b.[currency]  
      ,b.[ip]  
      ,b.[transdesc]  
      ,b.[sdiscount]  
      ,0 [scomm]  
      ,b.[spositiontaking]  
      ,0 [swinlost]  
      ,b.[srecommend]  
      ,b.[Username]  
      ,b.[CurrencyName]  
      ,b.[virtualrate]  
      ,b.custom1 [oddstype]  
      ,b.[statusID]  
      ,NULL [currency2]  
      ,b.[balance]  
      ,0 [SecAcceptFlag]  
      ,0 [transid2]  
      ,NULL [RecommDate]  
  FROM dbo.translog b WITH(NOLOCK)  
  WHERE b.translogid IN (SELECT TransID FROM @tmpListTransID WHERE TicketType=2)  
  AND b.GameID IN (801,803,804,805,806)  
    
  --Update translog for MGSL  
  UPDATE tl  
  SET  
   tl.Status = 'Void',  
   tl.StatusID = 102,  
   tl.creator = @UserID  
  FROM dbo.translog tl WITH(ROWLOCK,UPDLOCK)  
  WHERE (tl.translogid IN (SELECT TransID FROM @tmpListTransID WHERE TicketType=2)  
   OR tl.translogid IN (SELECT refno FROM @tmpListTransID WHERE TicketType=1)  
  )  
  AND tl.GameID IN (801,803,804,805,806)  
    
  --Update resultID in translog for MGSL  
  UPDATE tl  
  SET  
   tl.custom3 = (   
       SELECT rs.ResultID   
       FROM DBPRO.bodb02.dbo.ResultDetail3rd rs WITH(NOLOCK)   
       WHERE (  
         (ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, tl.transdesc,0) <> 0)  
         OR  
         tl.GameID = 806  
        )  
        AND rs.GameID = tl.GameID   
        AND rs.VendorID = 5    
        AND rs.MatchID = tl.EventID     
      )  
  FROM dbo.translog tl WITH(ROWLOCK,UPDLOCK)  
  WHERE (tl.translogid IN (SELECT TransID FROM @tmpListTransID WHERE TicketType=2)  
   OR tl.translogid IN (SELECT refno FROM @tmpListTransID WHERE TicketType=1)  
  )  
  AND tl.GameID IN (801,803,804,805,806) AND ISNULL(tl.Custom3,'') = ''  
    
  --Update resultID in bettrans for MGSL  
  UPDATE b  
  SET b.betid = (   
       SELECT rs.ResultID   
       FROM DBPRO.bodb02.dbo.ResultDetail3rd rs WITH(NOLOCK)   
       WHERE (  
         (ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0)  
         OR  
         b.Bettype = 806  
        )  
        AND rs.GameID = b.Bettype   
        AND rs.VendorID = 5    
        AND rs.MatchID = b.MatchID     
      )  
  FROM dbo.bettrans b WITH(ROWLOCK,UPDLOCK)  
  WHERE b.refno IN (SELECT TransID FROM @tmpListTransID WHERE TicketType=2)  
  AND b.Bettype IN (801,803,804,805,806) AND b.BetID IS NULL  
    
  --Update new transid  
  UPDATE main  
  SET main.TransID = b.TransID  
  FROM @tmpListTransID main  
   INNER JOIN dbo.bettrans b WITH(NOLOCK) ON main.refno = b.refno AND main.Bettype = b.Bettype  
  WHERE main.TicketType=2 AND b.Bettype IN (801,803,804,805,806)  
   
 --*****MGSL PROCESS - END  
   
   
 --Back up  
 INSERT INTO zzzbettrans  
  (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)  
 SELECT transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype  
 FROM bettrans with (nolock)  
 WHERE transid IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))    
   
 --Back up BetTrade's subtickets (901,902,903)    
 INSERT INTO zzzbettrans  
  (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)  
 SELECT sb.transid, sb.custid, CURRENT_TIMESTAMP, sb.oddsid, sb.hdp1, sb.hdp2, sb.odds, sb.stake, sb.status, sb.winlost, sb.livehomescore, sb.liveawayscore, sb.liveindicator, sb.betteam, sb.creator , sb.refno, sb.winlostdate, sb.betfrom, sb.betcheck, 
sb.checktime, sb.matchid, sb.bettype  
 FROM bettrans b with (nolock)  
  INNER JOIN bettrans sb WITH (nolock) ON b.transid = sb.refno AND b.matchid = sb.matchid AND sb.BetType IN (901,902,903)  
 WHERE b.transid IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))   
  
 UPDATE   
  bettrans WITH (ROWLOCK, UPDLOCK)  
 SET [status]   = 'Void'       
 WHERE  
  transid IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))  
    
 -- Update BetTrade's subtickets (901,902,903)   
 UPDATE   
  bettrans WITH (ROWLOCK, UPDLOCK)  
 SET [status]   = 'Void'        
 WHERE  
  refno IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))  
  AND Bettype IN (901, 902, 903)  
  
   
 -- Control concurrency problems - start    
  --Get error TransID  
  INSERT INTO @ErrorTransID(TransID)  
  SELECT DISTINCT t.TransID  
  FROM @tmpListTransID t  
   INNER JOIN zzzbettrans z WITH(NOLOCK) ON t.TransID = z.refno AND z.Bettype = 901  
   LEFT JOIN @tmpListTransID t2 ON t2.TransID = z.TransID  
  WHERE t2.TransID IS NULL  
  UNION  
  SELECT DISTINCT t.TransID  
  FROM @tmpListTransID t  
   INNER JOIN bettrans b WITH(NOLOCK) ON t.TransID = b.TransID AND b.betdaqid = 0  
   LEFT JOIN zzzbettrans z WITH(NOLOCK) ON t.TransID = z.refno AND z.Bettype = 901  
  WHERE z.TransID IS NULL  
  UNION  
  SELECT DISTINCT t.TransID  
  FROM @tmpListTransID t  
   INNER JOIN bettrans b WITH(NOLOCK) ON t.TransID = b.TransID AND b.betdaqid = 0  
   INNER JOIN zzzbettrans z WITH(NOLOCK) ON t.TransID = z.TransID  
  WHERE z.CustID <> b.CustID  
    
  -- Rollback BetTrade's main tickets  
  UPDATE  b  
  SET b.status = z.Status  
  FROM bettrans b WITH (ROWLOCK, UPDLOCK)   
   INNER JOIN zzzbettrans z  WITH (ROWLOCK, UPDLOCK) ON b.TransID = z.TransID     
  WHERE  
   b.TransID IN (SELECT transid FROM @ErrorTransID)  
     
  -- Rollback BetTrade's subtickets (901,902,903)   
  UPDATE  b  
  SET b.status = z.Status  
  FROM bettrans b WITH (ROWLOCK, UPDLOCK)   
   INNER JOIN zzzbettrans z  WITH (ROWLOCK, UPDLOCK) ON b.TransID = z.TransID     
  WHERE  
   b.refno IN (SELECT transid FROM @ErrorTransID)  
   AND b.Bettype IN (901, 902, 903)  
    
  -- DELETE balance/backup/delete data   
  DELETE FROM zzzbettrans   
  WHERE TransID IN (SELECT transid FROM @ErrorTransID)  
   OR (Refno IN (SELECT transid FROM @ErrorTransID) AND Bettype IN(901,902,903))  
     
  DELETE db  
  FROM @tmpListTransID db  
  INNER JOIN bettrans b WITH (ROWLOCK, UPDLOCK) ON db.TransID = b.TransID  
  WHERE db.TransID IN (SELECT transid FROM @ErrorTransID)  
   OR   
    ( b.refno IN (SELECT transid FROM @ErrorTransID) AND b.Bettype IN (901,902,903))  
   
 -- Control concurrency problems - end  
   
 INSERT INTO #BeforeUpd (custid, balance)  
 SELECT b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance  
 FROM bettrans b WITH (NOLOCK)  
 WHERE b.transid IN (SELECT transid FROM @tmpListTransID)  
 GROUP BY b.CustID  
   
 --update bettrans  
 UPDATE bettrans WITH (UPDLOCK,ROWLOCK)   
 SET  winlost=actual_stake,ruben=1,statuswinlost=6, creator = @UserID,  
   awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0,statusID = 102  
 WHERE transid IN (SELECT TransID FROM @tmpListTransID WHERE bettype NOT IN (901,902,903))   
   
 --update bettrans  
 UPDATE bettrans WITH (UPDLOCK,ROWLOCK)   
 SET  winlost=actual_stake,ruben=1,statuswinlost=6, creator = @UserID,  
   awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0,statusID = 102  
 WHERE refno IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))  
  AND Bettype IN (901, 902, 903)    
    
 --Update BetTrade selling information        
  -- Insert BetTradeSellingCancel  
  INSERT INTO [dbo].[BetTradeSellingCancelled]  
      ([TicketID]  
      ,[Remark]  
      ,[BTBuyBack]  
      ,[BTComission]  
      ,[AfterBalance]  
      ,[Owner]  
      ,[Cancelled]  
      ,[ChangeDate]  
      ,[CreateDate]  
      ,TradeID)  
   SELECT b.refno  
    , 'SB void ticket due to ' + @Reason  
    ,b.actual_stake - b902.actual_stake
    ,0  
    ,0  
    ,'SB'  
    ,1  
    ,GETDATE()  
    ,GETDATE()  
    ,btc.TradeID  
   FROM @tmpListTransID t  
   INNER JOIN bettrans b WITH(NOLOCK)  
	ON b.Refno = t.TransID AND b.BetType = 901  
	INNER JOIN bettrans b902 WITH(NOLOCK)  
	ON b902.Refno = t.TransID AND b902.BetType = 902 
   INNER JOIN [dbo].[BetTradeSelling] btc WITH(NOLOCK)  
   ON btc.TicketID = b.refno  
   LEFT JOIN [dbo].[BetTradeSellingCancelled] c WITH(NOLOCK)   
   ON c.[TicketID] = b.refno  
  WHERE c.[BTBuyBack] IS NULL AND t.Bettype NOT IN(901,902,903)  
    
  --Update  
  UPDATE main  
  SET  
   [Remark] = 'SB void ticket due to ' + @Reason,  
   [BTBuyBack] = b.actual_stake - b902.actual_stake,  
   [BTComission] = 0,  
   [Owner] = 'SB',  
   [Cancelled] = 1,  
   [ChangeDate] = GETDATE(),  
   AfterBalance = (SELECT ISNULL(SUM(CASE   
        WHEN ruben = 1  
         THEN winlost - actual_stake + playercomm  
        ELSE 0  
        END), 0)  
        FROM dbo.bettrans WITH (NOLOCK)  
        WHERE custid = b.custid  
        )  
  FROM [dbo].[BetTradeSellingCancelled] main WITH (ROWLOCK, UPDLOCK)  
  INNER JOIN bettrans b WITH(NOLOCK)  
   ON b.Refno = main.[TicketID] AND b.BetType = 901  
   INNER JOIN bettrans b902 WITH(NOLOCK)  
	ON b902.Refno = main.[TicketID] AND b902.BetType = 902  
  WHERE main.[TicketID] IN (SELECT transid FROM @tmpListTransID WHERE Bettype NOT IN(901,902,903))  
    
   
 --Get data after update  
 INSERT INTO #AfterUpd (custid, balance)  
 SELECT b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance  
 FROM bettrans b WITH (NOLOCK)  
 WHERE b.transid IN (SELECT transid FROM @tmpListTransID)  
 GROUP BY b.CustID   
   
 ---INSERT data into pending balance table   
 INSERT INTO BalancePendingCredit (custid,Balance)  
 SELECT  a.custid, (a.balance - b.balance) as Balance  
 FROM  #BeforeUpd b  
 INNER JOIN #AfterUpd a    
   ON a.custid = b.custid  
 WHERE     (a.balance - b.balance) > 0  
  
 INSERT INTO BalancePendingDebit (custid,Balance)  
 SELECT  a.custid, ABS(a.balance - b.balance) as Balance  
 FROM  #BeforeUpd b  
 INNER JOIN #AfterUpd a    
   ON a.custid = b.custid  
 WHERE     (a.balance - b.balance) < 0  
   
 --Metric API Calling  
 SELECT m.homeid,  
   m.awayid,  
   m.matchcode,  
   m.eventdate,  
   m.leagueid,  
   b.custid,  
   GETDATE() AS DATETIME,  
   isnull(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,  
   showtime AS GameEvent,  
   b.bettype,  
   b.odds,    
   b.OddsType,   
   b.transdate,  
   b.bettype,  
   b.refno transid,  
   b.refno,  
   b.betteam,  
   b.betcheck,  
   b.hdp1,  
   b.hdp2,  
   b.betfrom,  
   b.livehomescore,  
   b.liveawayscore,  
   b.liveindicator,  
   cr.username creator,  
   usr.username username,
   b.stake,       
   b.status,  
   b.winlost,  
   b.playercomm as comm,        
   b.currency,  
   b.betid,  
   b.transdesc  
 FROM bettrans b WITH (NOLOCK)  
   INNER JOIN Match m WITH (NOLOCK) ON b.matchID = m.matchid  
   INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
   INNER JOIN CustDB.dbo.customer usr WITH (NOLOCK) ON usr.custid = b.custid   
 WHERE b.refno IN (SELECT refno FROM @tmpListTransID WHERE bettype BETWEEN 801 AND 806)  
   AND @isExistMatch = 1   
   AND b.bettype BETWEEN 801 AND 806  
     
 DROP TABLE #BeforeUpd  
 DROP TABLE #AfterUpd   
     
 SELECT @LogData = 'Delete transaction for custid:' +cast(@custid as varchar(10))+' transid:' + cast(@strTransID as varchar(8000))+ ' by_login:' + @username + 'IP:' + cast(@IP as varchar(15)) + ' reason: ' + @reason  
 EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData  
    
 ------ release data of TempVariableNumBer table    
 WHILE (1 = 1)  
 BEGIN  
     SELECT TOP 1 @KeyId = t.KeyID,  
            @MatchId = t.matchid  
     FROM   @tmpListTransID t  
   INNER JOIN @LockTbl lstt ON t.KeyID = lstt.KeyID AND t.matchid = lstt.KeyValue  
     WHERE  t.Bettype <> 9 AND t.matchid IN (SELECT v.KeyValue  
                              FROM   dbo.TempVariableNumber v with(NOLOCK)  
                              WHERE  v.KeyID = t.KeyID)  
             AND lstt.IsLocked = 1  
       
     IF @@rowcount = 0  
         BREAK;  
     DELETE   
     FROM   TempVariableNumber   
     WHERE  KeyID = @KeyId  
            AND KeyValue = @MatchId  
       
     IF @@Error = 0  
     BEGIN  
     BEGIN  
         TRY  
         EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
              @UserID = @UserID,  
              @Matchid = @MatchId,  
              @KeyID = @KeyID,  
              @ActionID = 0,  
              @Remark = 'DEL SUCCESS SPName=NAP_BettransRecoverBet'  
     END TRY  
       
     BEGIN CATCH  
      SELECT @Remark = 'DEL SUCCESS SPName=NAP_BettransRecoverBet ErrMsg='   
             + LEFT(ERROR_MESSAGE(), 400)  
        
      EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
           @UserID = @UserID,  
           @Matchid = @MatchId,  
           @KeyID = @KeyID,  
           @ActionID = 0,  
           @Remark = @Remark  
     END CATCH  
       
     END  
     ELSE  
     BEGIN TRY  
      EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
           @UserID = @UserID,  
           @Matchid = @MatchId,  
           @KeyID = @KeyID,  
           @ActionID = 0,  
           @Remark = 'DEL FAILED SPName=NAP_BettransRecoverBet'  
     END TRY  
     BEGIN CATCH  
      SELECT @Remark = 'DEL FAILED SPName=NAP_BettransRecoverBet ErrMsg='   
             + LEFT(ERROR_MESSAGE(), 400)  
        
      EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking   
           @UserID = @UserID,  
           @Matchid = @MatchId,  
           @KeyID = @KeyID,  
           @ActionID = 0,  
           @Remark = @Remark  
     END CATCH  
       
     UPDATE @LockTbl  
  SET IsLocked = 0  
  WHERE KeyID = @KeyId AND KeyValue = @MatchId  
 END  
   
 IF @isExistParlay = 1 AND @UpdSystemSettings > 0  
 BEGIN  
  UPDATE SystemSettings WITH (ROWLOCK, UPDLOCK)  
  SET VValue = '0'  
  WHERE VName = 'isCalculatingParlay'  
 END  
   
 --Return Error TransIDs  
 SELECT * FROM @ErrorTransID  
   
END  
GO
GRANT EXECUTE ON [dbo].[NAP_BettransSpecialDelBetID_Del] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransSpecialDelBetID_Del] TO [vnteam] AS [dbo]
