
ALTER PROCEDURE [dbo].[Acc_BettransDelSpecialDel_EarlyKO_Checking_xtest]
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
	@betcount INT = 0 OUTPUT,
	@betmcount INT = 0 OUTPUT
AS

/*

	Created by: 20120921@Lukas
	Task : checking before delete ticket information for early kickoff
	DB: DBTRANS.bodb02
	Original:

	Revisions:   

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

	------ Check for concurrent running of match
	IF @isParlay IN (0,2)
	BEGIN 
		IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S') 
		BEGIN
			IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
			BEGIN
				SELECT  @ErrCode = 101,
						@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
				RETURN
			END
		END
	END
	------ Check for concurrent running for Parlay 
	IF @isParlay IN (1,2)
	BEGIN 	
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
			BEGIN
				SELECT @ErrCode = 102
				SELECT @ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'
		
				RETURN
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
					)	AND INF.ROLEID = 1
						AND BD.betfrom IN ('D', 'M', 'E', 'L') 
			UNION ALL
				SELECT INF.Custid, INF.username 
				FROM custinfo INF WITH(nolock) 
					INNER JOIN #BetmDelete BMD ON INF.Custid = BMD.Custid 
					WHERE INF.srecommend in (
						SELECT custid FROM Dep_CustSuper WITH (NOLOCK)						
					)	AND INF.ROLEID = 1
						AND BMD.betfrom IN ('D', 'M', 'E', 'L') 
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
		WHERE #BetDelete.betfrom IN ('D', 'M', 'E', 'L')
			AND CustID IN (SELECT CustID FROM @DepositCust)
			--AND custid not in (SELECT custid FROM #SpecialCust)
			AND custid not in (SELECT custid FROM @12EUCust) --12EU
			--        AND custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
			AND custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
			AND mrecommend not in (SELECT custid FROM @MasterMHC)		
		
		DELETE FROM #BetmDelete
		WHERE betfrom IN ('D', 'M', 'E', 'L')
			AND CustID IN (SELECT CustID FROM @DepositCust)
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
			AND #BetDelete.betfrom IN ('D', 'M', 'E', 'L')
			AND CustID IN (SELECT CustID FROM @DepositCust)
			------AND custid not in (SELECT custid FROM #SpecialCust)
			AND (custid not in (SELECT custid FROM @12EUCust) --12EU
			--AND custid not in (SELECT custid FROM @Mansion88Cust) --MANSION88
			AND custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
			AND mrecommend not in (SELECT custid FROM @MasterMHC))			
		
		DELETE FROM #BetmDelete
		WHERE
			transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
			AND betfrom IN ('D', 'M', 'E', 'L')
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

	
	SELECT @betcount = count(1)
	FROM #BetDelete
	
	SELECT @betmcount = count(1)
	FROM #BetmDelete

	DROP TABLE #BetDelete	
	DROP TABLE #BetmDelete	
	
SET NOCOUNT OFF
END
 

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecialDel_EarlyKO_Checking_xtest] TO [bodbAdminNet] AS [dbo]