ALTER PROCEDURE [dbo].[Acc_BettransDelSpecialDel_EarlyKO]
    @matchid INT,
    @DelOption TINYINT = 0,
    @KickOffDate datetime,
    @transids VARCHAR(4000) = 'All',-- for custom delete (Deposit bets)
    @bettypes VARCHAR(128) = 'All',
    @betteam1378 NVARCHAR(10),
    @betteam515 NVARCHAR(10),    
    @betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
    @hdp SMALLMONEY,
    @UserName NVARCHAR(50),
    @UserPwd NVARCHAR(50),
    @UserID INT,
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT,    
    @DelOption_BD TINYINT = 0,
    @transids_BD VARCHAR(4000) = '',-- for custom delete BetDaq
    @DelOption_12EU TINYINT = 0,
    @transids_12EU VARCHAR(4000) = '',-- for custom delete 12EU
    @IP VARCHAR(15) = '',
    @DelOption_MHC TINYINT = 0,
    @transids_MHC VARCHAR(4000) = '',-- for custom delete master MHC
    @SAFilter tinyint = 0 ,
    @reason		NVARCHAR(500) = ''	

AS

/*
Created by: Elly
Task : Delete ticket information for early kickoff
DB: DBTXN/bodb02
Original:

Revisions:
    20110804@Elly: delete combination mix parlay ticket for the match due to early kick off
    20110826@Elly: Remove system parlay
    20110831@Elly: correct transid and return SubTransID more
    20110914@Elly: add second to date of @LogData    
    20110920@Henry: add new deposit site for Bodog
    20110922@Tom: Add new bettypes 30, apply new bet type 1st correct score on Sport Books
				Replace parameter input @betteam4 => @betteam430
	20110929@Tom: Email notification for BEST-ODDs's UUS.
	20111012@Tom: Optimize variable Customer table: @12EUCust ,@DepositCust, @UUSCust.
	20111019@Viet: update bettransm.winlostdate once deleting ticket
	20111026@Henry: add new deposit sites: SilverGoose8, Vwin, Galaxy, SunGame (change from Suncity)
	20111028@Sophia: Update Balance and check settle date
					 Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam', 'VnQaTeam'
	20111201@Henry: Change Galaxy to Tycoon		
	20111219@Sophia: Send mail to internal when Currency is UUS, not to care the site anymore		 
	20111221@Sophia: When checking Permission to delete tickets, not to check username anymore.
	20111223@Lukas: add more bettype 29
	20120110@Sophia: Select from table #BetmDelete to put data into @DepositCust, @12EUCust, @UUSCust, @RealCurrCust table
	20120131@Henry: Change Sungame username prefix
	20120210@Daniel: Add filter param to list out SA (secondAccept) tickets:
	20120509@Henry: get deposit super from Dep_CustSuper instead of table Customer (exclude 12Bet)
	20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype, f_GetChoice for odds, Oddstype, betteam
	20120711@Sophia: . Always insert custID into temp table @DepositCust, @12EUCust, @MasterMHC, not to check condition before insert. 
					 . Optimize code of send mail for Deposit and 12EU
					 . Add condition 'L' in betfrom to check Deposit
	20120913@Sophia: Check for concurrent running
	20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 
	20130128@Elodie: Change link server DB03 to DBPOLICY
					 Write more log on DBTXN server in case of DBLOG server failure
	20130526@Johnson: Add param @reason to log the reason delete bets
	20131210@Kathy: Using Dep_CustSuper table to find deposit ticket instead of betfrom in ('D', 'M', 'E', 'L') [Redmine:#9321]
	
Param's Explanation: Special bet delete option
	@@betteam4: bettype =4: Correct Score; bettype =30: 1st Correct Score
	@@betteam6: bettype=6: Total Goal
	@@betteam14: bettype=14: First Goal/Last Goal
	@@betteam16: bettype=16: Half Time/Full Time
	
    @@DelOption = 0: No Delete (need to remove DepositBets out of #BetDelete)
    @@DelOption = 1: Delete All (no need to remove DepositBets out of #BetDelete)
    @@DelOption = 2: Optional Delete (remove DepositBets with option)

    @@DelOption_BD = 0: No Delete (need to remove BetDaq out of #BetDelete)
    @@DelOption_BD = 1: Delete All (no need to remove BetDaq out of #BetDelete)
    @@DelOption_BD = 2: Optional Delete (remove BetDaq with option)

    @@DelOption_12EU = 0: No Delete (need to remove 12EU out of #BetDelete)
    @@DelOption_12EU = 1: Delete All (no need to remove 12EU out of #BetDelete)
    @@DelOption_12EU = 2: Optional Delete (remove 12EU with option)

    @@DelOption_MHC = 0: No Delete (need to remove MHC out of #BetDelete)
    @@DelOption_MHC = 1: Delete All (no need to remove MHC out of #BetDelete)
    @@DelOption_MHC = 2: Optional Delete (remove MHC with option)
    
    - @SAFilter: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only
*/
BEGIN
SET NOCOUNT ON


	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDeleteEarlyKickOff]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
	RETURN
	--end
	
	--Check settled Date
	DECLARE @eventdate Datetime 
	SELECT	@eventdate = eventdate
	FROM	match WITH (NOLOCK)
	WHERE	matchid = @matchid
			
	EXEC dbo.Acc_CheckSettledDate @winlostdate = @eventdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN
	--end

	DECLARE @LogData NVARCHAR(500)
	SELECT @ErrCode = 0

	IF not exists (SELECT 1
		FROM dbo.customer WITH (NOLOCK)
		WHERE   customer.userpwd = @UserPwd
			AND custid = @UserID
			AND roleid>=5)
	BEGIN
		SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' because of early kick off at '+CAST(@KickOffDate as varchar(30)) + ' reason: ' + @reason
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
			
	IF EXISTS(SELECT 1 FROM dbo.match WITH(NOLOCK) WHERE matchid=@matchid AND eventstatus='completed')
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can not delete completed match.'
		RETURN
	END
	
	----################### Check for concurrent running ###################----
	DECLARE @isParlay TINYINT 
	
	IF EXISTS (SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29))	
		AND EXISTS (SELECT 1 FROM dbo.bettransm AS b WITH(NOLOCK) WHERE b.matchid=@matchid  AND b.transdate>=@KickOffDate AND b.statusID NOT IN (101,102) AND b.liveindicator=0 AND betfrom <>'P')
	BEGIN 	
		IF @bettypes IN ('9','29','9^29','29^9')
			SET @isParlay = 1  --- Only Parlay
		ELSE
			SET @isParlay = 2  --- Parlay and other bettype
	END	
	ELSE 
		SET @isParlay = 0 ---Not have Parlay
	
	DECLARE @Remark VARCHAR(500)
	------ Check for concurrent running of match
	IF @isParlay IN (0,2)
	BEGIN 
		IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
		BEGIN
			SELECT  @ErrCode = 101,
					@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END		
		INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
		IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH				
		ELSE 
		BEGIN
			SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END
	END
	------ Check for concurrent running for Parlay 
	IF @isParlay IN (1,2)
	BEGIN 	
		IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
		BEGIN
			SELECT @ErrCode = 102
			SELECT @ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'
			
			---- release data of TempVariableNumber before return
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid	
			IF (@@Error = 0)
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
			ELSE
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID = @UserID, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO'
				END TRY
				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID = @UserID, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = @Remark
				END CATCH
			END
			RETURN
		END
		ELSE 
		BEGIN
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '1'
			WHERE	VName = 'isCalculatingParlay'
		END
	
	END 	
	----################### End of check for concurrent running ###################----
	
	CREATE TABLE #BetDelete (transid BIGINT,refno bigint,custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
	CREATE TABLE #BetmDelete (transid BIGINT,refno bigint,custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
		
	DECLARE @12EUCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @DepositCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @Status TABLE (statusID TINYINT)
	DECLARE @MasterMHC TABLE (custid INT)
	 
	/*
	INSERT INTO @Status
	SELECT 'Void' UNION ALL
	SELECT 'Reject' UNION ALL
	SELECT 'WON' UNION ALL
	SELECT 'LOSE' UNION ALL
	SELECT 'DRAW'
	*/
	INSERT INTO @Status
	SELECT 102 UNION ALL
	SELECT 101 UNION ALL
	SELECT 112 UNION ALL
	SELECT 113 UNION ALL
	SELECT 111
	

------------------***** Insert all data into #BetDelete,#BetmDelete *****------------------	
	
	--bettype <> 4
	INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM dbo.bettrans b WITH (nolock)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b.bettype=fb.val
	WHERE
		b.matchid=@matchid	
		AND b.transdate>=@KickOffDate	
		AND b.liveindicator=0		
		AND CASE
			WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
			WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END               
			ELSE betteam 
		END = betteam
		AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE
											WHEN @hdp = 9999 THEN 1
											WHEN @hdp = (hdp1 + hdp2) THEN 1
											ELSE 0
										  END
			ELSE 1 END = 1
		AND b.bettype NOT IN(4,6,14,16,30)
		AND b.betfrom <>'P'
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
	

	--bettype = 4
	INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
	WHERE
		b.matchid=@matchid	
		AND b.transdate>=@KickOffDate	
		AND b.liveindicator=0		
		AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam430 = 'All' THEN betteam ELSE @betteam430 END,'^'))
		AND b.bettype in (4,30)
		AND b.betfrom <>'P'
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
	WHERE
		b.matchid=@matchid	
		AND b.transdate>=@KickOffDate	
		AND b.liveindicator=0		
		AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam6 = 'All' THEN betteam ELSE @betteam6 END,'^'))
		AND b.bettype = 6
		AND b.betfrom <>'P'
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS goal ON goal.val=b.betteam --dbo.Acc_SplitIndex(b.betteam,':',2)
	WHERE
		b.matchid=@matchid	
		AND b.transdate>=@KickOffDate	
		AND b.liveindicator=0		
		AND b.bettype = 14
		AND b.betfrom <>'P'
		AND (@betteam14 = 'All' OR goal.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
	WHERE
		b.matchid=@matchid	
		AND b.transdate>=@KickOffDate	
		AND b.liveindicator=0		
		AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam16 = 'All' THEN betteam ELSE @betteam16 END,'^'))
		AND b.bettype = 16
		AND b.betfrom <>'P'
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
				
	--GET sub ticket of the matchid for mix parlay
	IF EXISTS (SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29))	
		AND EXISTS (SELECT 1 FROM dbo.bettransm AS b WITH(NOLOCK) WHERE b.matchid=@matchid  AND b.transdate>=@KickOffDate AND b.statusID NOT IN (101,102) AND b.liveindicator=0 AND betfrom <>'P')
	BEGIN	
		INSERT INTO #BetmDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
		SELECT DISTINCT b.transid,b.refno,b.custid, c.recommend, c.mrecommend, c.srecommend, b.betfrom, b.statusID
		FROM dbo.bettransm AS b with (NOLOCK)
			INNER JOIN dbo.customer AS c WITH(NOLOCK) ON c.custid=b.custid		
			INNER JOIN dbo.bettrans bt WITH(NOLOCK) ON b.refno = bt.refno 
			INNER JOIN (SELECT CONVERT(SMALLINT,val) AS bettype FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29)) t ON t.bettype = bt.bettype	
		WHERE	b.matchid=@matchid   
			AND b.transdate>=@KickOffDate		
			AND b.liveindicator=0			
			AND b.betfrom <>'P'
			AND bt.matchid IN (9,29) AND bt.bettype IN (9,29)
			AND CASE when @SAFilter = 2 then 0 else 1 END = 1
			AND (bt.betid = 0 OR bt.betid IS NULL)			
	END

------------------***** End of insert all data into #BetDelete,#BetmDelete *****------------------	
		
	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113)
			UNION ALL 
			SELECT 1 FROM #BetmDelete WHERE statusID IN (111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		
		-----Release data of TempVariableNumber table before
		IF @isParlay IN (0,2)
		BEGIN 
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid	
			IF (@@Error = 0)
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
			ELSE
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID = @UserID, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO'
				END TRY
				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID = @UserID, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = @Remark
				END CATCH
			END
		END 
		
		-----Release data of SystemSettings table before
		IF @isParlay IN (1,2)
		BEGIN 	
			UPDATE	SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingParlay'
		END

		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
		DELETE FROM #BetmDelete WHERE statusID IN (SELECT * FROM @Status)
	END



------------------***** Insert Custid of each type into its temp table *****------------------		
	----INSERT Deposit CUSTOMER
	--IF NOT (@DelOption = 0 OR (@DelOption=2 AND @transids=''))
	--	BEGIN
			INSERT INTO @DepositCust (custid, username)
			SELECT INF.Custid, INF.username 
				FROM custinfo INF WITH(nolock) 
					INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
					WHERE INF.srecommend in (
						SELECT custid FROM Dep_CustSuper WITH (NOLOCK)
						--WHERE site <> '12Bet'
						/*
						SELECT Custid FROM customer (nolock) WHERE UserName like 'MS88Super%' AND ROLEID=4 --mansion88
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'ALogSuper%' AND ROLEID=4 --Alog
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'DELASuper%' AND ROLEID=4 -- dela
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'SPONSuper%' AND ROLEID=4 --spondemo
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'TLCSuper%' AND ROLEID=4 --tlc
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'Z88Super%' AND ROLEID=4 --zzun88
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'MFSuper%' AND ROLEID=4 -- mayfair
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'SUGSuper%' AND ROLEID=4 -- SunGame   
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'BEZBETSuper%' AND ROLEID=4 --BEZBET
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'HAIFASuper%' AND ROLEID=4 --HAIFA
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'BODOGSuper%' AND ROLEID=4 --BODOG
						UNION ALL
						SELECT Custid FROM customer (nolock) WHERE UserName like 'SG8Super%' AND ROLEID=4 --SILVERGOOSE8
						UNION ALL
						SELECT Custid FROM customer (nolock) WHERE UserName like 'TycoonSuper%' AND ROLEID=4 --Tycoon
						UNION ALL
						SELECT Custid FROM customer (nolock) WHERE UserName like 'VwinSuper%' AND ROLEID=4 --Vwin
						*/
					)	AND INF.ROLEID = 1
						--AND BD.betfrom IN ('D', 'M', 'E', 'L') 
			UNION ALL
				SELECT INF.Custid, INF.username 
				FROM custinfo INF WITH(nolock) 
					INNER JOIN #BetmDelete BMD ON INF.Custid = BMD.Custid 
					WHERE INF.srecommend in (
						SELECT custid FROM Dep_CustSuper WITH (NOLOCK)
						--WHERE site <> '12Bet'
						/*
						SELECT Custid FROM customer (nolock) WHERE UserName like 'MS88Super%' AND ROLEID=4 --mansion88
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'ALogSuper%' AND ROLEID=4 --Alog
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'DELASuper%' AND ROLEID=4 -- dela
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'SPONSuper%' AND ROLEID=4 --spondemo
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'TLCSuper%' AND ROLEID=4 --tlc
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'Z88Super%' AND ROLEID=4 --zzun88
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'MFSuper%' AND ROLEID=4 -- mayfair
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'SUGSuper%' AND ROLEID=4 -- SunGame   
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'BEZBETSuper%' AND ROLEID=4 --BEZBET
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'HAIFASuper%' AND ROLEID=4 --HAIFA
						UNION All
						SELECT Custid FROM customer (nolock) WHERE UserName like 'BODOGSuper%' AND ROLEID=4 --BODOG
						UNION ALL
						SELECT Custid FROM customer (nolock) WHERE UserName like 'SG8Super%' AND ROLEID=4 --SILVERGOOSE8
						UNION ALL
						SELECT Custid FROM customer (nolock) WHERE UserName like 'TycoonSuper%' AND ROLEID=4 --Tycoon
						UNION ALL
						SELECT Custid FROM customer (nolock) WHERE UserName like 'VwinSuper%' AND ROLEID=4 --Vwin
						*/
					)	AND INF.ROLEID = 1
						--AND BMD.betfrom IN ('D', 'M', 'E', 'L') 
		--END

	----INSERT 12EU CUSTOMER
	--IF NOT (@DelOption_12EU = 0 OR (@DelOption_12EU=2 AND @transids_12EU=''))
	--	BEGIN
			INSERT INTO @12EUCust (custid,username)
			SELECT INF.custid,INF.username 
			FROM customer INF WITH (nolock)
				INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
				WHERE INF.UserName = '12EU'
			UNION ALL
			SELECT INF.custid,INF.username 
			FROM customer INF WITH (nolock)
				INNER JOIN #BetmDelete BMD ON INF.Custid = BMD.Custid 
				WHERE INF.UserName = '12EU'
	--	END
		
	--INSERT UUS  CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT INF.custid, INF.username 
	FROM custinfo INF (nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend IN(
				SELECT custid FROM customer (nolock) Where CURRENCY = 20 AND roleid = 4
			) AND INF.roleid = 1
	UNION ALL
	SELECT INF.custid, INF.username 
	FROM custinfo INF (nolock) 
		INNER JOIN #BetmDelete BMD ON INF.Custid = BMD.Custid 
		WHERE INF.srecommend IN(
				SELECT custid FROM customer (nolock) Where CURRENCY = 20 AND roleid = 4
			) AND INF.roleid = 1

	--INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	INSERT INTO @RealCurrCust (CustID, username)
	SELECT		INF.custid, INF.username 
	FROM		custinfo INF WITH (NOLOCK) 
	INNER JOIN	#BetDelete BD ON INF.Custid = BD.Custid 
	WHERE		INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
				AND INF.roleid = 1 
				AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')		
	UNION ALL
	SELECT		INF.custid, INF.username 
	FROM		custinfo INF WITH (NOLOCK) 
	INNER JOIN	#BetmDelete BMD ON INF.Custid = BMD.Custid 
	WHERE		INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
				AND INF.roleid = 1 
				AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')		
	
	---- INSERT MASTER MHC
	--IF NOT (@DelOption_MHC = 0 OR (@DelOption_MHC=2 AND @transids_MHC=''))
	--	BEGIN
			INSERT INTO @MasterMHC(custid)
			SELECT 105181
			union all
			SELECT 118473
			union all
			SELECT 105183
	--	END

------------------***** End of insert Custid of each type into its temp table  *****------------------		

------------------***** Remove data no need to special delete out of #BetDelete *****------------------	

	--FOR Delete Deposit
	IF @DelOption = 0 or (@DelOption=2 AND @transids='')
	BEGIN
		DELETE FROM #BetDelete
		WHERE CustID IN (SELECT CustID FROM @DepositCust)
			--AND custid not in (SELECT custid FROM #SpecialCust)
			AND custid not in (SELECT custid FROM @12EUCust) --12EU
			--        AND custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
			AND custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
			AND mrecommend not in (SELECT custid FROM @MasterMHC)		
		
		DELETE FROM #BetmDelete
		WHERE CustID IN (SELECT CustID FROM @DepositCust)
			--AND custid not in (SELECT custid FROM #SpecialCust)
			AND custid not in (SELECT custid FROM @12EUCust) --12EU
			--        AND custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
			AND custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
			AND mrecommend not in (SELECT custid FROM @MasterMHC)		
	END
	IF @DelOption = 2 AND  @transids <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE
			transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
			--AND #BetDelete.betfrom IN ('D', 'M', 'E', 'L')
			AND CustID IN (SELECT CustID FROM @DepositCust)
			------AND custid not in (SELECT custid FROM #SpecialCust)
			AND (custid not in (SELECT custid FROM @12EUCust) --12EU
			--AND custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
			AND custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
			AND mrecommend not in (SELECT custid FROM @MasterMHC))			
		
		DELETE FROM #BetmDelete
		WHERE
			transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
			--AND betfrom IN ('D', 'M', 'E', 'L')
			AND CustID IN (SELECT CustID FROM @DepositCust)
			------AND custid not in (SELECT custid FROM #SpecialCust)
			AND (custid not in (SELECT custid FROM @12EUCust) --12EU
			--AND custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
			AND custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
			AND mrecommend not in (SELECT custid FROM @MasterMHC))	
	END

	--FOR Delete BetDaq(BQUS888,BQUSMLB,BQUSNBA,BQUS)
	IF @DelOption_BD = 0 or (@DelOption_BD=2 AND @transids_BD='')
	BEGIN
		DELETE FROM #BetDelete 
		WHERE
		--custid in (SELECT custid FROM #SpecialCust WHERE username in ('BQUS888','BQUSMLB','BQUSNBA') )  
			custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
		
		DELETE FROM #BetmDelete 
		WHERE custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
	END
	IF @DelOption_BD = 2 AND  @transids_BD <> ''
	BEGIN
		DELETE FROM #BetDelete		
		WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username in ('BQUS888','BQUSMLB','BQUSNBA') )
			custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
			AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_BD, ','))
		
		DELETE FROM #BetmDelete		
		WHERE custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
			AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_BD, ','))
	END

	--FOR Delete 12EU
	IF @DelOption_12EU = 0 or (@DelOption_12EU = 2 AND @transids_12EU='')
	BEGIN
		DELETE FROM #BetDelete 
		WHERE
		--custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')
			custid in (SELECT custid FROM @12EUCust)
		
		DELETE FROM #BetmDelete 
		WHERE custid in (SELECT custid FROM @12EUCust)
	END
	IF @DelOption_12EU = 2 AND  @transids_12EU <> ''
	BEGIN 
		DELETE FROM #BetDelete
		WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')
			custid in (SELECT custid FROM @12EUCust)
			AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_12EU, ','))
		
		DELETE FROM #BetmDelete
		WHERE custid in (SELECT custid FROM @12EUCust)
			AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_12EU, ','))
	END

	-- For Delete master MHCEU (105181), MHCRM (118473), MHCUS(105183)
	IF @DelOption_MHC = 0 or (@DelOption_MHC = 2 AND @transids_MHC ='')
	BEGIN
		DELETE FROM #BetDelete WHERE mrecommend in (SELECT custid FROM @MasterMHC)
		
		DELETE FROM #BetmDelete WHERE mrecommend in (SELECT custid FROM @MasterMHC)
	END
	IF @DelOption_MHC = 2 AND  @transids_MHC <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE mrecommend in (SELECT custid FROM @MasterMHC)
			AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_MHC, ','))
		
		DELETE FROM #BetmDelete
		WHERE mrecommend in (SELECT custid FROM @MasterMHC)
			AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_MHC, ','))
	END

------------------***** End of Remove data no need to special delete out of #BetDelete  *****------------------

------------------***** Begin special delete early kickoff *****------------------

	-- STEP 1 : BackUp of bettrans and bettransm
	INSERT INTO	zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM	dbo.bettrans AS b WITH (nolock)
		INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	WHERE		
		b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
		AND b.matchid = @matchid
		AND b.liveindicator = 0
		AND b.transdate>=@KickOffDate
		AND CASE
		WHEN b.bettype in (1,3,7,8) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
		WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END
		ELSE betteam
		END = betteam

	-- BackUp bettransm tickets into zzzbettrans
	/***
		Date: 20120112@Lukas
		Temporary solution
		ADD MORE LOG IN ZZZBETTRANS FOR VIEWING LOG TW SITE
	***/
	INSERT INTO	zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM	bettransm AS b WITH (nolock)
		INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	WHERE
		b.matchid = @matchid
		AND b.liveindicator = 0
		AND b.transdate>=@KickOffDate	
	/*
		END -  ADD MORE LOG IN ZZZBETTRANS FOR VIEWING LOG TW SITE
	*/

	INSERT INTO	zzzbettransm
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM	bettransm AS b WITH (nolock)
		INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	WHERE
		b.matchid = @matchid
		AND b.liveindicator = 0
		AND b.transdate>=@KickOffDate		
		
	declare @matchdate datetime
	select @matchdate = eventdate from match with(nolock) where matchid = @matchid

	-- Create temp table to calculate balance
	CREATE TABLE #BeforeUpd (
			custid		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				balance		 MONEY)
				
	--Get data before update
	INSERT INTO #BeforeUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	INNER JOIN #BetDelete d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	GROUP BY b.CustID
	
	-- STEP 2 : Update
	--update void single ticket in bettrans
	UPDATE b 
	SET winlost=b.actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
		awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
	FROM dbo.bettrans AS b WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	
	--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	GROUP BY b.CustID

	---insert data into pending balance table 
		INSERT INTO BalancePendingCredit (custid,Balance)
		SELECT		a.custid, (a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) > 0

		INSERT INTO BalancePendingDebit (custid,Balance)
		SELECT		a.custid, ABS(a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) < 0

		
	-- update totalbets
	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)

	INSERT INTO @Total	
	SELECT
		oddsid,
		SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
		SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
	FROM dbo.bettrans AS b WITH (nolock)
		INNER JOIN dbo.exchange AS e WITH (nolock) ON b.currency = e.exchangeid
	WHERE bettype in (1,3,7,8) AND ruben = 0 AND oddsid <> 0 AND matchid = @matchid
	GROUP BY oddsid
	
		
	UPDATE odds WITH (rowlock, updlock)
	SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	FROM @Total t 
	WHERE odds.oddsid = t.oddsid AND odds.matchid = @matchid
	
	CREATE TABLE #Currency (TransID bigint, Refno bigint, CurrencyID tinyint,oddstype tinyint, ParlayType smallint)
	
	IF EXISTS (SELECT 1 FROM #BetmDelete)
	BEGIN	
		declare @match_tmp varchar(20), @rowcount INT, @step INT, @transid_tmp VARCHAR(2000)

		select	@match_tmp = CONVERT(VARCHAR(20),@matchid),
				@step = 0
		

		DECLARE @transtbl TABLE (id INT IDENTITY, transid BIGINT)
		INSERT INTO @transtbl (transid)
					SELECT transid
					FROM #BetmDelete
		SELECT @rowcount = @@ROWCOUNT

		WHILE @step < @rowcount
		BEGIN

			SET @transid_tmp = ''

			SELECT @transid_tmp  = @transid_tmp + CONVERT(VARCHAR(20),transid)  + ','	
			FROM @transtbl
			WHERE id > @step AND id <= @step + 100
			
			SET @step = @step + 100

			EXEC Admin_Calculate_9m 
					@matchid	= @MatchID,
					@fth		= 0, 
					@fta		= 0,
					@hth		= 0,  
					@hta		= 0,
					@matchdate	= @matchdate,
					@action		= 'VOID',
					@VoidTransID= @transid_tmp,
					@UserID		= @UserID
		END

	--***********System parlay*********---
		IF EXISTS (	SELECT TOP 1 1
					FROM bettrans b WITH(NOLOCK) 
						INNER JOIN #BetmDelete r ON b.refno = r.refno
					WHERE b.matchid = 29 AND b.bettype = 29
				   ) 
		BEGIN
			EXEC dbo.Admin_Calculate_29_PreCal @matchids = @match_tmp
			EXEC dbo.Admin_Calculate_29 @matchids = @match_tmp, @matchdate = @matchdate
			
		---********* Calculate balance for system parlay********---
				CREATE TABLE #BeforeUpdSP (
							custid		 INT,
							balance		 MONEY)
						
				CREATE TABLE #AfterUpdSP(
								custid		 INT,
								balance		 MONEY)
								
				--Get data before update
				INSERT INTO #BeforeUpdSP (custid, balance)
				SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
				FROM	bettrans b WITH (NOLOCK)
					INNER JOIN #BetmDelete r ON b.refno = r.refno
				WHERE b.matchid = 29 AND b.bettype = 29
				GROUP BY b.CustID		

		--Settlement System parlay (changed balance)
			EXEC dbo.Admin_Calculate_29_Summary 

		--Get data after update
				INSERT INTO #AfterUpdSP (custid, balance)
				SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
				FROM	bettrans b WITH (NOLOCK)
					INNER JOIN #BetmDelete r ON b.refno = r.refno
				WHERE b.matchid = 29 AND b.bettype = 29
				GROUP BY b.CustID

			---insert data into pending balance table 
				INSERT INTO BalancePendingCredit (custid,Balance)
				SELECT		a.custid, (a.balance - b.balance) as Balance
				FROM		#BeforeUpdSP b
				INNER JOIN	#AfterUpdSP a 	
						ON	a.custid = b.custid
				WHERE	    (a.balance - b.balance) > 0

				INSERT INTO BalancePendingDebit (custid,Balance)
				SELECT		a.custid, ABS(a.balance - b.balance) as Balance
				FROM		#BeforeUpdSP b
				INNER JOIN	#AfterUpdSP a 	
						ON	a.custid = b.custid
				WHERE	    (a.balance - b.balance) < 0
				
				DROP TABLE #BeforeUpdSP
				DROP TABLE #AfterUpdSP
	---********* End of calculate balance for system parlay********---

		END


		INSERT INTO #Currency
		SELECT b2.transid,b2.Refno,b2.Currency,b2.oddstype, b2.bettype
		FROM dbo.bettrans AS b2 WITH(NOLOCK)
			INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON b2.refno=d.refno
		WHERE matchid IN (9,29) AND bettype IN (9,29) --mix parlay
			AND liveindicator=0
			AND transdate>=@KickOffDate
			AND (b2.betid = 0 OR b2.betid IS NULL) 				
	END
	
	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' because of early kick off at '+CONVERT(varchar(23),@KickOffDate,121) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + ' reason: ' + @reason
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

	--after delete, return all deleted deposit bets with additional information for mailing
	IF exists(
		SELECT 1 
		FROM #BetDelete AS d WITH(NOLOCK) 
			INNER JOIN dbo.bettrans b ON D.transid = b.transid
		WHERE  d.custid in (SELECT custid FROM @DepositCust)
			OR d.custid in (SELECT custid FROM @12EUCust)  
--			or d.custid in (SELECT custid FROM @12EUCust)  
--			or d.custid in (SELECT custid FROM @DepositCust)
			or d.custid IN (SELECT custid FROM @UUSCust)
			or d.custid IN (SELECT custid FROM @RealCurrCust)
		UNION ALL
		SELECT 1 
		FROM #BetmDelete AS d WITH(NOLOCK) 
			INNER JOIN dbo.bettransm AS b WITH(NOLOCK) ON D.transid = b.transid
		WHERE  d.custid in (SELECT custid FROM @DepositCust)
			OR d.custid in (SELECT custid FROM @12EUCust)  			
--			or d.custid in (SELECT custid FROM @12EUCust)  
--			or d.custid in (SELECT custid FROM @DepositCust)
			or d.custid IN (SELECT custid FROM @UUSCust)
			or d.custid IN (SELECT custid FROM @RealCurrCust)
	)
	BEGIN
		IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
		BEGIN
			SELECT
				MATCH.teamid AS homeid,
				0 AS awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				CONVERT(BIT,0) AS IsNeutral
			FROM
				Outright AS MATCH WITH (NOLOCK)
			WHERE 
				MATCH.orid = @matchID
		END   
		ELSE
		BEGIN
			SELECT
				MATCH.homeid,
				MATCH.awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
			FROM
				MATCH WITH (NOLOCK)
			WHERE 
				MATCH.matchid = @matchID
		END

			SELECT
				c.username,
				c.username2,
				b.odds,  
				b.OddsType, 
				b.transdate,
				b.bettype,
				b.transid,
				b.transid AS SubTransID,
				b.refno,
				b.betteam,
				b.hdp1,
				b.hdp2,
				b.betfrom,
				b.livehomescore,
				b.liveawayscore,
				cr.username creator,
				b.stake,           
				b.currency,
				ag.site,
				--b.status,
				0 AS IsMP,
				0 as ParlayType
			FROM
				dbo.bettrans b WITH (NOLOCK)
				INNER JOIN dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
				INNER JOIN dbo.customer AS c WITH (NOLOCK) ON c.custid=b.custid				
				INNER JOIN dbo.customer ag WITH (NOLOCK) ON ag.custid=c.recommend
				INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid --AND d.refno=b.refno
			WHERE matchid=@matchid
				AND b.transdate>=@KickOffDate				
				AND b.liveindicator=0		
				AND (c.custid IN (SELECT custid FROM @DepositCust)
						OR  c.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete
					)
					--or  c.custid IN (SELECT custid FROM #SpecialCust WHERE username = '12EU') --Email 12EU if delete
--					or  c.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete
--					or c.custid IN (SELECT custid FROM @DepositCust)
--					)	
			UNION ALL
			SELECT
				customer.username,
				customer.username2,
				b.odds,  
				cy.OddsType, 
				b.transdate,
				b.bettype,
				cy.transid,
				b.transid AS SubTransID,
				b.refno,
				b.betteam,
				b.hdp1,
				b.hdp2,
				b.betfrom,
				b.livehomescore,
				b.liveawayscore,
				cr.username creator,
				b.stake,           
				cy.CurrencyID AS currency,
				ag.site,
				--b.status,
				1 AS IsMP,
				cy.ParlayType as ParlayType
			FROM
				dbo.bettransm b WITH (NOLOCK)
				INNER JOIN dbo.customer  WITH (NOLOCK) ON customer.custid=b.custid
				INNER JOIN dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
				INNER JOIN dbo.customer ag WITH (NOLOCK) ON customer.recommend = ag.custid				
				INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid --AND d.refno=b.refno
				INNER JOIN #Currency AS cy WITH(NOLOCK) ON cy.refno=b.refno
			WHERE matchid=@matchid
				AND b.transdate>=@KickOffDate				
				AND b.liveindicator=0		
				AND (  customer.custid IN (SELECT custid FROM @DepositCust)
						OR customer.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete
					)
					--or  customer.custid IN (SELECT custid FROM #SpecialCust WHERE username = '12EU') --Email 12EU if delete
--					or customer.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete
--					or customer.custid IN (SELECT custid FROM @DepositCust)
--				)	
			ORDER BY IsMP, b.transid						
	END
	
	
	SELECT bd.transid,
		bd.custid, mem.UserName        AS CustUserName,
		bd.recommend, ag.UserName    AS AgUserName,
		bd.mrecommend, mag.UserName AS MagUserName,
		bd.srecommend, sag.Username AS SagUserName
	FROM #BetDelete bd (nolock)
		INNER JOIN dbo.custinfo mem (nolock) ON bd.custid     = mem.custid
		INNER JOIN dbo.custinfo ag  (nolock) ON bd.recommend  = ag.custid
		INNER JOIN dbo.custinfo mag (nolock) ON bd.mrecommend = mag.custid
		INNER JOIN dbo.custinfo sag (nolock) ON bd.srecommend = sag.custid
	UNION ALL
	SELECT b.transid,
			bd.custid, mem.UserName        AS CustUserName,
			bd.recommend, ag.UserName    AS AgUserName,
			bd.mrecommend, mag.UserName AS MagUserName,
			bd.srecommend, sag.Username AS SagUserName
	FROM dbo.bettrans b WITH (NOLOCK) 
		INNER JOIN #BetmDelete AS bd with(nolock) ON bd.refno=b.refno AND b.matchid=9 AND b.bettype=9
		INNER JOIN dbo.custinfo mem (nolock) ON bd.custid     = mem.custid
		INNER JOIN dbo.custinfo ag  (nolock) ON bd.recommend  = ag.custid
		INNER JOIN dbo.custinfo mag (nolock) ON bd.mrecommend = mag.custid
		INNER JOIN dbo.custinfo sag (nolock) ON bd.srecommend = sag.custid
	
-----BEGIN : Send mail Internal when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'	/OR UUS Currency
IF exists(
		SELECT 1 
		FROM #BetDelete AS d WITH(NOLOCK) 
			INNER JOIN dbo.bettrans b ON D.transid = b.transid
		WHERE  d.custid IN (SELECT custid FROM @UUSCust)
			or d.custid IN (SELECT custid FROM @RealCurrCust)
		UNION ALL
		SELECT 1 
		FROM #BetmDelete AS d WITH(NOLOCK) 
			INNER JOIN dbo.bettransm AS b WITH(NOLOCK) ON D.transid = b.transid
		WHERE  d.custid IN (SELECT custid FROM @UUSCust)
			or d.custid IN (SELECT custid FROM @RealCurrCust)
	)
	BEGIN
			SELECT
				c.username,
				c.username2,
				b.odds,  
				b.OddsType, 
				b.transdate,
				b.bettype,
				b.transid,
				b.transid AS SubTransID,
				b.refno,
				b.betteam,
				b.hdp1,
				b.hdp2,
				b.betfrom,
				b.livehomescore,
				b.liveawayscore,
				cr.username creator,
				b.stake,           
				b.currency,
				ag.site,
				--b.status,
				0 AS IsMP,
				1 as isInternalMail,
				0 as ParlayType
			FROM
				dbo.bettrans b WITH (NOLOCK)
				INNER JOIN dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
				INNER JOIN dbo.customer AS c WITH (NOLOCK) ON c.custid=b.custid				
				INNER JOIN dbo.customer ag WITH (NOLOCK) ON ag.custid=c.recommend
				INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid --AND d.refno=b.refno
			WHERE matchid=@matchid
				AND b.transdate>=@KickOffDate				
				AND b.liveindicator=0		
				AND ( c.custid IN (SELECT custid FROM @UUSCust)
					  or c.custid IN (SELECT custid FROM @RealCurrCust)
					)	
			UNION ALL
			SELECT
				customer.username,
				customer.username2,
				b.odds,  
				cy.OddsType, 
				b.transdate,
				b.bettype,
				cy.transid,
				b.transid AS SubTransID,
				b.refno,
				b.betteam,
				b.hdp1,
				b.hdp2,
				b.betfrom,
				b.livehomescore,
				b.liveawayscore,
				cr.username creator,
				b.stake,           
				cy.CurrencyID AS currency,
				ag.site,
				--b.status,
				1 AS IsMP,
				1 as isInternalMail,
				cy.ParlayType as ParlayType
			FROM
				dbo.bettransm b WITH (NOLOCK)
				INNER JOIN dbo.customer  WITH (NOLOCK) ON customer.custid=b.custid
				INNER JOIN dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
				INNER JOIN dbo.customer ag WITH (NOLOCK) ON customer.recommend = ag.custid				
				INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid --AND d.refno=b.refno
				INNER JOIN #Currency AS cy WITH(NOLOCK) ON cy.refno=b.refno
			WHERE matchid=@matchid
				AND b.transdate>=@KickOffDate				
				AND b.liveindicator=0		
				AND (customer.custid IN (SELECT custid FROM @UUSCust)
					 or customer.custid IN (SELECT custid FROM @RealCurrCust)
					)	
			ORDER BY IsMP, b.transid	
	END
----END : Send mail Internal when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR UUS Currency
			
						
	DROP TABLE #BetDelete	
	DROP TABLE #BetmDelete
	DROP TABLE #Currency
	
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd
		
	-----Release data of TempVariableNumber table
	IF @isParlay IN (0,2)
	BEGIN 
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
			ELSE
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID = @UserID, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO'
				END TRY
				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
						@UserID = @UserID, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = @Remark
				END CATCH
			END
	END 
	
	-----Release data of SystemSettings table
	IF @isParlay IN (1,2)
	BEGIN 	
		UPDATE	SystemSettings WITH (ROWLOCK, UPDLOCK)
		SET		VValue = '0'
		WHERE	VName = 'isCalculatingParlay'
	END	
	
SET NOCOUNT OFF
END
 
GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecialDel_EarlyKO] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecialDel_EarlyKO] TO [vnteam]