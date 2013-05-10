
ALTER PROCEDURE [dbo].[Acc_BettransDelSpecial_NumberGame_Checking_xtest]
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
    @transids_MHC	VARCHAR(4000)	= '',-- for custom delete master MHC
	@betcount		INT				= 0 OUTPUT
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

	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
		---- check and not allow attempt to delete same game while it's still not finish
		IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
		BEGIN
			SELECT  @ErrCode = 101,
					@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END		
	END
	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		----Check by SystemSettings
		IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingNGManual')
		BEGIN
			SELECT @ErrCode = 102
			SELECT @ErrMsg = 'Another number game re-calculation is in progress or some tickets of this match are being deleted, please wait a few seconds until the on-going process has finished and try again.'
						
			RETURN
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



	SELECT @betcount = COUNT(1)
	FROM #BetDelete
	
	DROP TABLE #BetDelete
	--DROP TABLE #SpecialCust
	

END



GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial_NumberGame_Checking_xtest] TO [bodbAdminNet]

