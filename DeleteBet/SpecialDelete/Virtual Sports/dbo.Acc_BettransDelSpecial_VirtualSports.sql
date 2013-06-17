ALTER PROCEDURE [dbo].[Acc_BettransDelSpecial_VirtualSports]
    @matchid INT,
    @DelOption TINYINT = 0,
    @f_transid BIGINT,
    @t_transid BIGINT,
    @transids VARCHAR(4000) = '',-- for custom delete (Deposit bets)
    @bettypes VARCHAR(128) = '',
    @betteam1201 NVARCHAR(10),
    @betteam1205 NVARCHAR(10),
    @betteam1204 VARCHAR(120) = '',
    @betteam1206 varchar(120) = '',
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
    @transids_MHC VARCHAR(4000) = ''-- for custom delete master MHC	    
AS
/*
Created by: 20120816@Elodie
Task : delete bets of Virtual sports
DB: DBTXN/bodb02
Original: Acc_BettransDelSpecial

Revisions:
	- 20120913@Sophia: Add table TempVariableNumber to check and not to allow attempt to delete same game while it's still not finish
	- 20130103@Elodie: Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table																 						   
	- 20130128@Elodie: Change link server DB03 to DBPOLICY
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20130617@Johnson: change alias StakePositiontaking to stake
						   	    
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
    
    - @betteam1201: include Handicap(1201), Over/Under(1203), Double chance(1224) of Virtual sports
	- @betteam1205: include FT1x2(1205) of Virtual sports
	- @betteam1204: include Correct score(1204) of Virtual sports
	- @betteam1206: include Total goal(1206) of Virtual sports
*/
BEGIN
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

	IF not exists ( SELECT 1
					FROM customer WITH (NOLOCK)
					WHERE   customer.userpwd = @UserPwd
						and custid = @UserID
						and roleid>=5)
	BEGIN
		SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid)
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
	
	---- check and not allow attempt to delete same game while it's still not finish
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
			@Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial_VirtualSports'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverBet_LiveCS ErrMsg=' + left(error_message(), 400)
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
	-----------	
	
	CREATE TABLE #BetDelete (transid BIGINT, custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
	
	DECLARE @12EUCust TABLE     (custid INT, username VARCHAR(30))
	DECLARE @DepositCust TABLE  (custid INT, username VARCHAR(30))
	DECLARE @UUSCust TABLE      (custid INT, username VARCHAR(30))
	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))
		
	DECLARE @MasterMHC TABLE (custid INT)
	DECLARE @Status TABLE (statusID TINYINT)	
	INSERT INTO @Status
		SELECT 102 UNION ALL
		SELECT 101 UNION ALL
		SELECT 112 UNION ALL
		SELECT 113 UNION ALL
		SELECT 111	

------------------***** Insert all data into #BetDelete *****------------------
	--bettype <> 1204, 1206
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=b.bettype
	WHERE
		b.matchid=@matchid 
		AND b.transid between @f_transid and @t_transid
		and CASE
			WHEN b.bettype in (1201,1203) THEN CASE WHEN @betteam1201 = 'ALL' THEN betteam ELSE @betteam1201 END
			WHEN b.bettype in (1205) THEN CASE WHEN @betteam1205 = 'ALL' THEN betteam ELSE @betteam1205 END               
			ELSE betteam 
		END = betteam    		
		AND CASE WHEN b.bettype in (1201,1203) THEN CASE
												WHEN @hdp = 9999 THEN 1
												WHEN @hdp = (hdp1 + hdp2) THEN 1
												ELSE 0
											  END
		ELSE 1 END = 1
		AND b.bettype NOT IN(1204,1206)
        
	--bettype = 1204
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam1204,'^') AS bt ON b.betteam=CONVERT(varchar(3),bt.val)
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid
		and b.bettype = 1204
		AND (@betteam1204='All' OR bt.val IS NOT NULL)
	
	--bettype = 1206
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam1206,'^') AS bt ON bt.val = b.betteam
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid		
		and b.bettype = 1206
		AND (@betteam1206='All' OR bt.val IS NOT NULL)
		
------------------***** End of insert all data into #BetDelete *****------------------		
			
	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		
		-----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid
		IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_VirtualSports'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_VirtualSports ErrMsg=' + left(error_message(), 400)
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
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_VirtualSports'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_VirtualSports ErrMsg=' + left(error_message(), 400)
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
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END

------------------***** Insert Custid of each type into its temp table *****------------------		
	
	--INSERT Deposit CUSTOMER	
	INSERT INTO @DepositCust (custid, username)
	SELECT INF.Custid, INF.username 
	FROM custinfo INF WITH(nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend in (SELECT custid FROM Dep_CustSuper WITH (NOLOCK)) 
				AND INF.ROLEID = 1
				AND BD.betfrom IN ('D', 'M', 'E', 'L')

	--INSERT 12EU CUSTOMER	
	INSERT INTO @12EUCust (custid,username)
	SELECT INF.custid,INF.username 
	FROM customer INF WITH (nolock)
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.UserName = '12EU'
		
	----INSERT UUS  CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT INF.custid, INF.username 
	FROM custinfo INF (nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend IN(SELECT custid FROM customer (nolock) Where CURRENCY = 20 AND roleid = 4) 
				AND INF.roleid = 1
	
	----INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	INSERT INTO @RealCurrCust (CustID, username)
	SELECT INF.custid, INF.username 
	FROM custinfo INF WITH (NOLOCK) 
		INNER JOIN	#BetDelete BD ON INF.Custid = BD.Custid 
	WHERE INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
			AND INF.roleid = 1 
			AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')					
			
	---- INSERT MASTER MHC
	INSERT INTO @MasterMHC(custid)
				SELECT 105181
				union all
				SELECT 118473
				union all
				SELECT 105183

------------------***** End of insert Custid of each type into its temp table  *****------------------		

------------------***** Remove data no need to special delete out of #BetDelete *****------------------

	--FOR Delete Deposit
	IF @DelOption = 0 or (@DelOption=2 and @transids='') 
	BEGIN
		DELETE FROM #BetDelete
		WHERE #BetDelete.betfrom IN ('D', 'M', 'E', 'L')
				AND CustID IN (SELECT CustID FROM @DepositCust)
				and custid not in (SELECT custid FROM @12EUCust) --12EU
				and custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq	       
				and mrecommend not in (SELECT custid FROM @MasterMHC)		
		
	END
	
	IF @DelOption = 2 and  @transids <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
				and #BetDelete.betfrom IN ('D', 'M', 'E', 'L')
				AND CustID IN (SELECT CustID FROM @DepositCust)
				and (custid not in (SELECT custid FROM @12EUCust) --12EU
				and custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
				and mrecommend not in (SELECT custid FROM @MasterMHC))							
	END

	--FOR Delete BetDaq(BQUS888,BQUSMLB,BQUSNBA,BQUS)
	IF @DelOption_BD = 0 or (@DelOption_BD=2 and @transids_BD='')
	BEGIN
		DELETE FROM #BetDelete WHERE custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
	END		
	
	IF @DelOption_BD = 2 and  @transids_BD <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
				AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_BD, ','))
	END

	--FOR Delete 12EU
	IF @DelOption_12EU = 0 or (@DelOption_12EU = 2 and @transids_12EU='')
	BEGIN
		DELETE FROM #BetDelete WHERE custid in (SELECT custid FROM @12EUCust)
	END
		
	IF @DelOption_12EU = 2 and  @transids_12EU <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE custid in (SELECT custid FROM @12EUCust)
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
	INSERT INTO zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	FROM
		bettrans b WITH (nolock)
	WHERE
		b.transid IN (SELECT transid FROM #BetDelete)
		AND b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
		AND b.matchid = @matchid
		AND CASE
			WHEN b.bettype in (1201,1203) THEN CASE WHEN @betteam1201 = 'ALL' THEN betteam ELSE @betteam1201 END
			WHEN b.bettype in (1205) THEN CASE WHEN @betteam1205 = 'ALL' THEN betteam ELSE @betteam1205 END
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
	UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
	SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
		awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
	WHERE transid in (SELECT transid FROM #BetDelete)	

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

	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

------after delete, return all deleted deposit bets and 12EU with additional information for mailing (not send mail for BETDAQ tickets)
	IF exists(
		SELECT 1 FROM #BetDelete INNER join bettrans b ON #BetDelete.transid = b.transid
		WHERE	( b.betfrom  IN ('D', 'M', 'E', 'L')
				  AND #BetDelete.custid IN (SELECT custid FROM @DepositCust) 
				) OR #BetDelete.custid IN (SELECT custid FROM @12EUCust)  			
			or #BetDelete.custid IN (SELECT custid FROM @UUSCust)
			or #BetDelete.custid IN (SELECT custid FROM @RealCurrCust)	    
		) 
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
		   
		SELECT
			customer.username,
			customer.username2,
			b.odds,  
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
			stake,           
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
		ORDER BY transid
		
	END

	SELECT  transid,
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
				stake,           
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
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd
	
	-----
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid	
	IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_VirtualSports'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_VirtualSports ErrMsg=' + left(error_message(), 400)
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
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_VirtualSports'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_VirtualSports ErrMsg=' + left(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial_VirtualSports] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecial_VirtualSports] TO [vnteam] 