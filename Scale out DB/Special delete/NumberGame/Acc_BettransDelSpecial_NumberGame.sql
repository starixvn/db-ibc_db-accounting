 ALTER PROCEDURE [dbo].[Acc_BettransDelSpecial_NumberGame_xtest]
    @matchid		INT,
    @DelOption		TINYINT			= 0,
    @f_transid		BIGINT,
    @t_transid		BIGINT,
    @transids		VARCHAR(4000)	= '',-- for custom delete (Deposit bets)
    @Dead			VARCHAR(100)	= '', -- bettype for dead-ball
	@Live			VARCHAR(100)	= '', -- bettype for live-ball
    @UserName		NVARCHAR(50),
    @UserPwd		NVARCHAR(50),
    @UserID			INT,
    @ErrMsg			NVARCHAR(200)	= '' OUTPUT,
    @ErrCode		INT				= 0 OUTPUT,
    @liveindicator	SMALLINT		= 0,
    @DelOption_BD	TINYINT			= 0,
    @transids_BD	VARCHAR(4000)	= '',-- for custom delete BetDaq
    @DelOption_12EU TINYINT			= 0,
    @transids_12EU	VARCHAR(4000)	= '',-- for custom delete 12EU
    @IP				VARCHAR(15)		= '',
    @DelOption_MHC	TINYINT			= 0,
    @transids_MHC	VARCHAR(4000)	= ''-- for custom delete master MHC
    
AS
/*
Created by: Lukas
Task : SP deletebet (Number Game)
DB: DBTRANS.bodb02
Original:account\deletebet.asp

Revisions:
    - 20110120@Henry: add new deposit site for Zzun88, Mayfair and Suncity
    - 20110408@Amy: Add new deposit site for Bezbet
					Change function to get Odds value and odds type
	- 20110729@Henry: add new deposit site for Haifa
	- 20110920@Henry: add new deposit site for Bodog
	- 20111013@Tom: 1.Email notification for BEST-ODDs's UUS.
					2.Optimize variable Customer table: @12EUCust ,@DepositCust, @UUSCust.
	- 20111028@Sophia: Update Balance and check settle date
	- 20111216@Sophia: Send mail to internal when Currency is UUS, not to care the site anymore
	- 20111221@Sophia: When checking Permission to delete tickets, not to check username anymore.
	- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
	- 20120717@Sophia: . Always insert custID into temp table @DepositCust, @12EUCust, @MasterMHC, not to check condition before insert. 
					   . Add condition 'L' in betfrom to check Deposit
					   . Fix @Dead+@Live to @Dead+'^'+@Live
	- 20120913@Sophia: Add table TempVariableNumber to check and not to allow attempt to delete same game while it's still not finish
	- 20120927@Lukas: put servername to control SP execution (CCS)
	
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

*/
BEGIN
	SET NOCOUNT ON	

	DECLARE @LogData NVARCHAR(500)
	SELECT	@ErrCode = 0
	
	
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
		----################ check concurrent running #####################----
		---- check by TempVariableNumber
		IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
		BEGIN
			SELECT  @ErrCode = 101,
					@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END

		INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
	END
	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		----Check by SystemSettings
		IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingNGManual')
		BEGIN
			SELECT @ErrCode = 102
			SELECT @ErrMsg = 'Another number game re-calculation is in progress or some tickets of this match are being deleted, please wait a few seconds until the on-going process has finished and try again.'
			
			----release data of TempVariableNumber table
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid

			RETURN
		END
		ELSE 
		BEGIN
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '1'
			WHERE	VName = 'isCalculatingNGManual'
		END
	END
	
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
		SELECT 101 UNION ALL
		SELECT 121		---- dummy ticket
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
		SELECT 121 UNION ALL    ---- dummy ticket
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
	
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)			
			SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
			FROM bettrans b WITH (nolock)
			WHERE
				b.matchid=@matchid 						
				AND
				b.transid BETWEEN @f_transid AND @t_transid						
				AND
				(   
					(
						b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead,'^'))
						AND 
						b.liveindicator = 0 
					)
					 OR
					(
						b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Live,'^'))
						AND 
						b.liveindicator = 1 
					)
				) 							


	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113) AND @username NOT IN ('steven','joe'))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		
		-----
		IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
		BEGIN
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid	
		END
		IF @@SERVERNAME IN ('DBTRANS','DB206')
		BEGIN
			----release data of systemSettings table before return
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'
		END
		
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END

	--IF NOT (@DelOption = 0 OR (@DelOption=2 AND @transids=''))
		INSERT INTO @DepositCust (custid, username)
		SELECT INF.custid, INF.username 
		FROM custinfo INF WITH(nolock) 
			INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE	INF.srecommend in ( SELECT custid FROM Dep_CustSuper WITH (NOLOCK) WHERE site IN ('12Bet', 'Alog'))		
				  AND INF.roleid = 1
				  AND BD.betfrom IN ('D', 'M', 'E', 'L')


	--INSERT 12EU CUSTOMER
	--IF NOT (@DelOption_12EU = 0 OR (@DelOption_12EU=2 AND @transids_12EU=''))
		INSERT INTO @12EUCust (custid,username)
			SELECT INF.custid,INF.username 
			FROM customer INF WITH (nolock)
				INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
				WHERE INF.username = '12EU'

	--INSERT UUS CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT INF.custid, INF.username 
	FROM custinfo INF (nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
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
			
	-- INSERT MASTER MHC
	--IF NOT (@DelOption_MHC = 0 OR (@DelOption_MHC=2 AND @transids_MHC=''))
		INSERT INTO @MasterMHC(custid)
				SELECT 105181
				union all
				SELECT 118473
				union all
				SELECT 105183

	--FOR Delete Deposit
	IF @DelOption = 0 or (@DelOption=2 and @transids='')
	BEGIN
		DELETE FROM #BetDelete
		WHERE #BetDelete.betfrom IN ('D', 'M', 'E', 'L')
		AND custid IN (Select custid FROM @DepositCust)
		--AND custid not in (SELECT custid FROM #SpecialCust)
		AND custid NOT IN (SELECT custid FROM @12EUCust) --12EU
		--and custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
		AND custid NOT IN (SELECT CustID FROM [f_GetBetDaqCustomer] (1)) --Betdaq       
		AND mrecommend NOT IN (SELECT custid FROM @MasterMHC)
	END
	IF @DelOption = 2 and  @transids <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE
			transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
			AND #BetDelete.betfrom IN ('D', 'M', 'E', 'L')
			AND custid IN (Select custid FROM @DepositCust)
			--AND custid not in (SELECT custid FROM #SpecialCust)
			AND (
				custid not in (SELECT custid FROM @12EUCust) --12EU
				--and custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
				AND custid NOT IN (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
				AND mrecommend NOT IN (SELECT custid FROM @MasterMHC))
	END

	--FOR Delete BetDaq(BQUS888,BQUSMLB,BQUSNBA,BQUS)
	IF @DelOption_BD = 0 or (@DelOption_BD=2 and @transids_BD='')
	BEGIN
		DELETE FROM #BetDelete 
		WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username in ('BQUS888','BQUSMLB','BQUSNBA') )  
			custid IN (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
	END
	IF @DelOption_BD = 2 AND  @transids_BD <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username in ('BQUS888','BQUSMLB','BQUSNBA') )
			custid IN (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
			AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_BD, ','))
	END

	--FOR Delete 12EU
	IF @DelOption_12EU = 0 or (@DelOption_12EU = 2 and @transids_12EU='')
	BEGIN
		DELETE FROM #BetDelete 
		WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')
			custid IN (SELECT custid FROM @12EUCust)
	END
	IF @DelOption_12EU = 2 and  @transids_12EU <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE
			--custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')
			custid IN (SELECT custid FROM @12EUCust)
			AND transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_12EU, ','))
	END

	-- For Delete master MHCEU (105181), MHCRM (118473), MHCUS(105183)
	IF @DelOption_MHC = 0 OR (@DelOption_MHC = 2 and @transids_MHC ='')
	BEGIN
		DELETE FROM #BetDelete 
		WHERE 
			mrecommend IN (SELECT custid FROM @MasterMHC)
	END
	IF @DelOption_MHC = 2 and  @transids_MHC <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE 
			mrecommend IN (SELECT custid FROM @MasterMHC)
			AND 
			transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids_MHC, ','))
	END


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
			AND b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead + '^' + @Live,'^'))
			AND b.matchid = @matchid	 

	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
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
	END
	


	-- STEP 2 : Update
	--    begin tran
	UPDATE 
		bettrans WITH (ROWLOCK, UPDLOCK)
	SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
		awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
	WHERE
		transid in (SELECT transid FROM #BetDelete)


	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
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
	END

	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
	END

	--after delete, return all deleted deposit bets with additional information for mailing
	IF exists(
		SELECT 1 FROM #BetDelete INNER join bettrans b ON #BetDelete.transid = b.transid
		WHERE ( b.betfrom  IN ('D', 'M', 'E', 'L') AND #BetDelete.custid IN (SELECT custid FROM @DepositCust) ) 
--		or  #BetDelete.custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')  
		or #BetDelete.custid in (SELECT custid FROM @12EUCust)
		or #BetDelete.custid in (SELECT custid FROM @DepositCust)
		or #BetDelete.custid IN (SELECT custid FROM @UUSCust)
		or #BetDelete.custid IN (SELECT custid FROM @RealCurrCust)
		)
	BEGIN
		IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead + '^' + @Live,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
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
			ag.site,
			b.liveindicator
		FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
			INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
			INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
		WHERE b.transid IN(SELECT transid FROM #BetDelete)
			and (
					(	b.betfrom  IN ('D', 'M', 'E', 'L') 
						AND b.custid IN (SELECT custid FROM @DepositCust)	
					)
			--			or  customer.custid IN (SELECT custid FROM #SpecialCust WHERE username = '12EU') --Email 12EU if delete
						or customer.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete
			--			or customer.custid IN (SELECT custid FROM @UUSCust)
			)   
		ORDER BY transid  
	END	

	SELECT	transid,
			bd.custid, mem.UserName     AS CustUserName,
			bd.recommend, ag.UserName   AS AgUserName,
			bd.mrecommend, mag.UserName AS MagUserName,
			bd.srecommend, sag.Username AS SagUserName
	FROM #BetDelete bd (nolock)
			INNER JOIN custinfo mem (nolock) ON bd.custid     = mem.custid
			INNER JOIN custinfo ag  (nolock) ON bd.recommend  = ag.custid
			INNER JOIN custinfo mag (nolock) ON bd.mrecommend = mag.custid
			INNER JOIN custinfo sag (nolock) ON bd.srecommend = sag.custid


-----Begin : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS
	IF exists(
	SELECT 1 FROM #BetDelete INNER join bettrans b ON #BetDelete.transid = b.transid
	WHERE	#BetDelete.custid IN (SELECT custid FROM @UUSCust)
			or #BetDelete.custid IN (SELECT custid FROM @RealCurrCust)
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
			ag.site,
			b.liveindicator
		FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
			INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
			INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
		WHERE	b.transid IN(SELECT transid FROM #BetDelete)
				AND ( customer.custid IN (SELECT custid FROM @UUSCust)
					  or customer.custid IN (SELECT custid FROM @RealCurrCust) 
				     )
		ORDER BY transid  	   
	END
	-----End : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS


	DROP TABLE #BetDelete
	--DROP TABLE #SpecialCust
	
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
		DROP TABLE #BeforeUpd
		DROP TABLE #AfterUpd
		
		-----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid	
		
		IF @@SERVERNAME IN ('DBTRANS','DB206')
		BEGIN
			----release data of systemSettings table
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'	
		END
	END
	
END



GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial_NumberGame_xtest] TO [bodbAdminNet]
