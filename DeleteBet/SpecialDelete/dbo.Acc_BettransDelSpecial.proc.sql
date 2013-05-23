ALTER PROCEDURE [dbo].[Acc_BettransDelSpecial]
    @matchid INT,
    @DelOption TINYINT = 0,
    @f_transid BIGINT,
    @t_transid BIGINT,
    @transids VARCHAR(4000) = '',-- for custom delete (Deposit bets)
    @bettypes VARCHAR(128) = '',
    @betteam1378 NVARCHAR(10),
    @betteam515 NVARCHAR(10),
    @betteam430 VARCHAR(120) = '',
    @betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
    @hdp SMALLMONEY,
    @UserName NVARCHAR(50),
    @UserPwd NVARCHAR(50),
    @UserID INT,
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT,
    @liveindicator SMALLINT = 0,
    @livehomescore smallint = NULL,
    @liveawayscore smallint = NULL,
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
    @DelOption_BD TINYINT = 0,
    @transids_BD VARCHAR(4000) = '',-- for custom delete BetDaq
    @DelOption_12EU TINYINT = 0,
    @transids_12EU VARCHAR(4000) = '',-- for custom delete 12EU
    @IP VARCHAR(15) = '',
    @DelOption_MHC TINYINT = 0,
    @transids_MHC VARCHAR(4000) = '',-- for custom delete master MHC	    
    @SAFilter tinyint = 0 ,
    @reason NVARCHAR(500) = ''
AS
BEGIN
/*
Created by: Thien Pham
Task : SP deletebet
DB: DBTXN/bodb02
Original:account\deletebet.asp

Revisions:

    - 20060525@ThienPham: remove refno
    - 20060208@ThienPham: Correct Refno
    - 20061127@HiepVo:
        + redefine how to get the data
        + change delete option, open for BetDag and 12EU
        + add 12EU to send mail list if delete
    - 20070517@ThienPham:  Rebuild for Account
    - 20080115@VinhTruong:
        + Add delete option for additional function, see detail below
        + Add return deleted deposit bets'information for mailing
    - 20090414@KhoaTran: Collected info of bets ticket are deleted into DB07.bodb_Message
    - 20090517@KhoaTran: Allow user to delete multiple bet types
    - 20090806@KhoaTran: Email notification for Mansion88
    - 20090919@Shifu: Log IP
    - 20090925@khoa: Deleted option for member belong to master  MHCRM, MHCEU, MHCUS
    - 20091007@Khoa: Add more condition to Delete live or Dead ball for bettype 2 & 12
    - 20091008@Simon: Get Odds && OddsType columns.
    - 20091012@Kiwi: remove custbetcredit and change to write log into userlog
    - 20091125@Kiwi: Remove comstatus because it's no used.
    - 20091227@Khoa: Suport more option search with Correct Score and remove table exchange
    - 20100424@Henry: UPDATE statusID of bettrans (StatusID = 102 for status VOID)
    -- 20100522@Henry: Change to use StatusID instead of Status in WHERE statement
    - 20100618@Khoa: Email notification for members belong to alog site
    - 20100622@Jamie: Fix how to get ALog Super
    - 20100917@Robert: include betfrom='e' into deposit group
    - 20101001@Henry: Using f_GetBetDaqCustomer to query betdaq customer
    - 20101003@Robert: Prompt msg with normal Admin
	- 20101005@Lukas: modify the condition to prompt msg with normal admin
	- 20101008@Henry: Change column transid from INT to BIGINT
	- 20101117@Lukas: separate deletion bet of both Asiabet & TLC
	- 20101118@Henry: Add new deposit site for TLC, SPONDEMO & DELA
	- 20101222@Johnson: change the length of parameter bettype
	- 20110120@Henry: add new deposit site for Zzun88, Mayfair and Suncity
	- 20110224@Henry: add new deposit site for Bezbet
	- 20110408@Amy: Change function to get Odds value and odds type
	- 20110729@Henry: add new deposit site for Haifa
	- 20110817@Elly: add bettype =6,14,16
	- 20110920@Henry: add new deposit site for Bodog
	- 20110922@Tom: Add new bettypes 30, apply new bet type 1st correct score on Sport Books
				Replace parameter input @betteam4 => @betteam430
	- 20110929@Tom: Email notification for BEST-ODDs's UUS.
	- 20111012@Tom: Optimize variable Customer table: @12EUCust ,@DepositCust, @UUSCust.
	- 20111026@Henry: add new deposit sites: SilverGoose8, Vwin, Galaxy, SunGame (change from Suncity)
	- 20111028@Sophia: Update Balance and check settle date
	- 20111110@Sophia:	Add new parametter @livehomescore, @liveawayscore, @transdate, to filter by livehomescore and liveawayscore.
						Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'
	- 20111201@Henry: Change Galaxy to Tycoon
	- 20111216@Sophia: Send mail to internal when Currency is UUS, not to care the site anymore
	- 20111221@Sophia: When checking Permission to delete tickets, not to check username anymore.
	- 20120131@Henry: Change Sungame username prefix
	- 20120210@Daniel: Add filter param to list out SA (secondAccept) tickets:
	- 20120309@Sophia: Change param @transdate to @FromTransdate and @ToTransdate
	- 20120509@Henry: get deposit super from Dep_CustSuper instead of table Customer (exclude 12Bet)
	- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
	- 20120711@Sophia: . Always insert custID into temp table @DepositCust, @12EUCust, @MasterMHC, not to check condition before insert. 
					   . Optimize code of send mail for Deposit and 12EU
					   . Add condition 'L' in betfrom to check Deposit
	- 20120913@Sophia: Add table TempVariableNumber to check and not to allow attempt to delete same game while it's still not finish
	- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 						   
	- 20130128@Elodie: Change link server DB03 to DBPOLICY
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20130526@Johnson: Add param @reason to log the reason delete bets 
		    
Param's Explanation: Special bet delete option
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
     
    -@liveindicator:
	 + 0: Dead
	 + 1: Live
	 + 2: All

*/

	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDelete]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
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
	DECLARE @Remark VARCHAR(500)
	SELECT @ErrCode = 0

	IF not exists (SELECT 1
					FROM customer WITH (NOLOCK)
					WHERE   customer.userpwd = @UserPwd
						and custid = @UserID
						and roleid>=5)
	BEGIN
		SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' reason: ' + @reason
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
	
	---- check and not allow attempt to delete same game while it's still not finish
	DECLARE @KeyID INT

	IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)
	BEGIN 	
		SET @KeyID = 2
	END
	ELSE
	BEGIN 	
		SET @KeyID = 1
	END

	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = @KeyID AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (@KeyID, @matchid)
	IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE 
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
	-------------------		
		
	CREATE TABLE #BetDelete (transid BIGINT, custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
	--CREATE TABLE #SpecialCust (custid int, username varchar(30))
	DECLARE @12EUCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @DepositCust TABLE (custid INT, username VARCHAR(30))
	
	DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @Status TABLE (statusID TINYINT)
	DECLARE @MasterMHC TABLE (custid INT)
	
	--Only steven can delete bet of "complete" match
	IF(@username = 'steven' OR @username = 'joe')
	BEGIN
		/*
		INSERT INTO @Status
		SELECT 'Void' UNION ALL
		SELECT 'Reject'
		*/
		INSERT INTO @Status
		SELECT 102 UNION ALL
		SELECT 101
	END
	ELSE   
	BEGIN -- Other Admin
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
		/*
		IF EXISTS (SELECT 1 FROM MATCH (NOLOCK) WHERE matchid=@matchid and eventstatus = 'completed')
		BEGIN
			SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled ticket'
			RETURN
		END
		*/
	END

------------------***** Insert all data into #BetDelete *****------------------
	--bettype <> 4
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=b.bettype
	WHERE
		b.matchid=@matchid 
		AND b.transid between @f_transid and @t_transid
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		--and status NOT IN(SELECT * FROM @Status)
		--AND statusID NOT IN (SELECT * FROM @Status)
		and CASE
			WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
			WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END               
			ELSE betteam 
		END = betteam    
		AND b.bettype NOT IN(4,6,14,16,30)
		AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE
													WHEN @hdp = 9999 THEN 1
													WHEN @hdp = (hdp1 + hdp2) THEN 1
													ELSE 0
												  END
		ELSE 1 END = 1
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
        
	--bettype = 4
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam430,'^') AS bt ON b.betteam=CONVERT(varchar(3),bt.val)
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype in (4,30)
		AND (@betteam430='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
			

	--Begin Elly add
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt ON bt.val=b.betteam
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid		
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 	
		and b.bettype = 6
		AND (@betteam6='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS bt ON b.betteam=CONVERT(varchar(3),bt.val)
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype = 14
		AND (@betteam14='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
			
		
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam16,'^') AS bt ON bt.val=b.betteam
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid		
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator	
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype = 16
		AND (@betteam16='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
	--End Elly add

------------------***** End of insert all data into #BetDelete *****------------------		
			
	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113) AND @username NOT IN ('steven','joe'))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		
		-----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = @KeyID AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
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
					) 
					AND INF.ROLEID = 1
					AND BD.betfrom IN ('D', 'M', 'E', 'L')
					
		--END

	----INSERT 12EU CUSTOMER
	--IF NOT (@DelOption_12EU = 0 OR (@DelOption_12EU=2 AND @transids_12EU=''))
	--	BEGIN
			INSERT INTO @12EUCust (custid,username)
			SELECT INF.custid,INF.username 
			FROM customer INF WITH (nolock)
				INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
				WHERE INF.UserName = '12EU'
	--	END
		
	----INSERT UUS  CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT INF.custid, INF.username 
	FROM custinfo INF (nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend IN(
				SELECT custid FROM customer (nolock) Where CURRENCY = 20 AND roleid = 4
			) AND INF.roleid = 1
	
	----INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	INSERT INTO @RealCurrCust (CustID, username)
	SELECT		INF.custid, INF.username 
	FROM		custinfo INF WITH (NOLOCK) 
	INNER JOIN	#BetDelete BD ON INF.Custid = BD.Custid 
	WHERE		INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
				AND INF.roleid = 1 
				AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')			
			
			
	---- INSERT MASTER MHC
	--IF NOT (@DelOption_MHC = 0 OR (@DelOption_MHC=2 AND @transids_MHC=''))
		INSERT INTO @MasterMHC(custid)
					SELECT 105181
					union all
					SELECT 118473
					union all
					SELECT 105183
		

	/*
	--INSERT SPECIAL CUSTOMER
	INSERT INTO #SpecialCust (custid,username)
	SELECT custid,username from customer with (nolock)
	where username in ('BQUS888','BQUSMLB','BQUSNBA','12EU')
	UNION ALL
	SELECT custid,username from @Mansion88Cust
	*/


------------------***** End of insert Custid of each type into its temp table  *****------------------		

------------------***** Remove data no need to special delete out of #BetDelete *****------------------

	--FOR Delete Deposit
	IF @DelOption = 0 or (@DelOption=2 and @transids='') 
		BEGIN
			DELETE FROM #BetDelete
			WHERE 
			#BetDelete.betfrom IN ('D', 'M', 'E', 'L')
			AND CustID IN (SELECT CustID FROM @DepositCust)
			--AND custid not in (SELECT custid FROM #SpecialCust)
			and custid not in (SELECT custid FROM @12EUCust) --12EU
	        --and custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
			and custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq	       
			and mrecommend not in (SELECT custid FROM @MasterMHC)		
			
		END
	IF @DelOption = 2 and  @transids <> ''
		BEGIN
			DELETE FROM #BetDelete
			WHERE
				transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
				and #BetDelete.betfrom IN ('D', 'M', 'E', 'L')
				AND CustID IN (SELECT CustID FROM @DepositCust)
	            --AND custid not in (SELECT custid FROM #SpecialCust)
				and (custid not in (SELECT custid FROM @12EUCust) --12EU
				--and custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
				and custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
				and mrecommend not in (SELECT custid FROM @MasterMHC))							
		END


	--FOR Delete BetDaq(BQUS888,BQUSMLB,BQUSNBA,BQUS)
	IF @DelOption_BD = 0 or (@DelOption_BD=2 and @transids_BD='')
		BEGIN
			DELETE FROM #BetDelete WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username in ('BQUS888','BQUSMLB','BQUSNBA') )  
			custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
		END
	IF @DelOption_BD = 2 and  @transids_BD <> ''
		BEGIN
			DELETE FROM #BetDelete
			WHERE
				--custid in (SELECT custid FROM #SpecialCust WHERE username in ('BQUS888','BQUSMLB','BQUSNBA') )
				custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
				AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_BD, ','))
		END

	--FOR Delete 12EU
	IF @DelOption_12EU = 0 or (@DelOption_12EU = 2 and @transids_12EU='')
		BEGIN
			DELETE FROM #BetDelete WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')
			custid in (SELECT custid FROM @12EUCust)
		END
	IF @DelOption_12EU = 2 and  @transids_12EU <> ''
		BEGIN
			DELETE FROM #BetDelete
			WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')
			custid in (SELECT custid FROM @12EUCust)
				AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_12EU, ','))
		END

	-- For Delete master MHCEU (105181), MHCRM (118473), MHCUS(105183)
	IF @DelOption_MHC = 0 or (@DelOption_MHC = 2 and @transids_MHC ='')
		BEGIN
			DELETE FROM #BetDelete WHERE mrecommend in (SELECT custid FROM @MasterMHC)
		END
	IF @DelOption_MHC = 2 and  @transids_MHC <> ''
		BEGIN
			DELETE FROM #BetDelete
			WHERE mrecommend in (SELECT custid FROM @MasterMHC)
				AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_MHC, ','))
		END
------------------***** End of Remove data no need to special delete out of #BetDelete  *****------------------

------------------***** Begin Special Delete *****------------------

	-- STEP 1 : BackUp
		INSERT INTO
			zzzbettrans
			(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
		SELECT
			 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
		FROM
			bettrans b WITH (nolock)
		WHERE
			b.transid IN (SELECT transid FROM #BetDelete)
			AND b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
			AND b.matchid = @matchid
			--and b.liveindicator = @liveindicator
			AND CASE
				WHEN b.bettype in (1,3,7,8) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
				WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END
				ELSE betteam
			END = betteam   


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
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID
	

	-- STEP 2 : Update
	--  begin tran
			UPDATE 
				bettrans WITH (ROWLOCK, UPDLOCK)
			SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
				awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
			WHERE
				transid in (SELECT transid FROM #BetDelete)

	-- update totalbets
	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)

	INSERT INTO @Total
	SELECT
		oddsid,
		SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
		SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
	FROM bettrans b WITH (nolock)
		INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
	WHERE bettype in (1,3,7,8) AND ruben = 0 AND oddsid <> 0 and matchid = @matchid
	GROUP BY oddsid

	UPDATE odds WITH (rowlock, updlock)
	SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @matchid

	--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
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

------------------***** End of Special Delete *****------------------

	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + ' reason: ' + @reason
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

------after delete, return all deleted deposit bets and 12EU with additional information for mailing (not send mail for BETDAQ tickets)
	IF exists(
		SELECT 1 FROM #BetDelete INNER join bettrans b ON #BetDelete.transid = b.transid
		WHERE	( b.betfrom  IN ('D', 'M', 'E', 'L')
				  AND #BetDelete.custid IN (SELECT custid FROM @DepositCust) 
				) OR #BetDelete.custid IN (SELECT custid FROM @12EUCust)  
			--or  #BetDelete.custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')  
--			or #BetDelete.custid IN (SELECT custid FROM @12EUCust)  
--			or #BetDelete.custid IN (SELECT custid FROM @DepositCust)
			or #BetDelete.custid IN (SELECT custid FROM @UUSCust)
			or #BetDelete.custid IN (SELECT custid FROM @RealCurrCust)	    
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
			customer.username,
			customer.username2,
			b.odds,  
			b.OddsType, 
			b.transdate,
			b.bettype,
			b.transid AS refno,
			betteam,
			hdp1,
			hdp2,
			betfrom,
			livehomescore,
			liveawayscore,
			cr.username creator,
			stake AS StakePositiontaking,           
			b.currency,
			ag.site
		FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
			INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
			INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
		WHERE b.transid IN(SELECT transid FROM #BetDelete)
			and (	
					( b.betfrom  IN ('D', 'M', 'E', 'L')
					  AND customer.custid IN (SELECT custid FROM @DepositCust)
					) OR customer.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete  
				)
			--or  customer.custid IN (SELECT custid FROM #SpecialCust WHERE username = '12EU') --Email 12EU if delete
--			or customer.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete
--			or customer.custid IN (SELECT custid FROM @DepositCust) 						      
--				)  
		ORDER BY transid
		
	END

	SELECT transid,
	bd.custid, mem.UserName        AS CustUserName,
	bd.recommend, ag.UserName    AS AgUserName,
	bd.mrecommend, mag.UserName AS MagUserName,
	bd.srecommend, sag.Username AS SagUserName
	FROM
	#BetDelete bd (nolock)
	INNER JOIN custinfo mem (nolock) ON bd.custid     = mem.custid
	INNER JOIN custinfo ag  (nolock) ON bd.recommend  = ag.custid
	INNER JOIN custinfo mag (nolock) ON bd.mrecommend = mag.custid
	INNER JOIN custinfo sag (nolock) ON bd.srecommend = sag.custid
	
	-----Begin : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS
	IF exists(
		SELECT 1 FROM #BetDelete 
		INNER join bettrans b ON #BetDelete.transid = b.transid
		WHERE	#BetDelete.custid IN (SELECT custid FROM @RealCurrCust)
				OR #BetDelete.custid IN (SELECT custid FROM @UUSCust)
	    	)
	BEGIN
		    SELECT
				customer.username,
				customer.username2,
				b.odds,  
				b.OddsType, 
				b.transdate,
				b.bettype,
				b.transid AS refno,
				betteam,
				hdp1,
				hdp2,
				betfrom,
				livehomescore,
				liveawayscore,
				cr.username creator,
				stake AS StakePositiontaking,           
				b.currency,
				ag.site
			FROM
				bettrans b WITH (NOLOCK)
				INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
				INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
				INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
			WHERE	b.transid IN(SELECT transid FROM #BetDelete)
					and (customer.custid IN (SELECT custid FROM @RealCurrCust)
					or customer.custid IN (SELECT custid FROM @UUSCust)
					)	     					   
			ORDER BY transid    	   
	END
	-----End : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS


	DROP TABLE #BetDelete
	--DROP TABLE #SpecialCust
	
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd

	-----
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = @KeyID AND KeyValue = @matchid	
	IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
	
	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecial] TO [ITVivi]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecial] TO [vnteam]