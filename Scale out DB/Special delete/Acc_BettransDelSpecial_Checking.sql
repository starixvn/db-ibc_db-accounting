
alter PROCEDURE [dbo].[Acc_BettransDelSpecial_Checking_xtest]
(
	@matchid		INT,
    @DelOption		TINYINT			= 0,
    @f_transid		BIGINT,
    @t_transid		BIGINT,
    @transids		VARCHAR(4000)	= '',-- for custom delete (Deposit bets)
    @bettypes		VARCHAR(128)	= '',
    @betteam1378	NVARCHAR(10),
    @betteam515		NVARCHAR(10),
    @betteam430		VARCHAR(120)	= '',
    @betteam6		VARCHAR(120)	= '',
	@betteam14		VARCHAR(120)	= '',
	@betteam16		VARCHAR(120)	= '',
    @hdp			SMALLMONEY,
    @UserName		NVARCHAR(50),
    @UserPwd		NVARCHAR(50),
    @UserID			INT,
    @ErrMsg			NVARCHAR(200)	= '' OUTPUT,
    @ErrCode		INT				= 0 OUTPUT,
    @liveindicator	SMALLINT		= 0,
    @livehomescore	SMALLINT		= NULL,
    @liveawayscore	SMALLINT		= NULL,
    @FromTransdate	DATETIME		= NULL,
	@ToTransdate	DATETIME		= NULL,
    @DelOption_BD	TINYINT			= 0,
    @transids_BD	VARCHAR(4000)	= '',-- for custom delete BetDaq
    @DelOption_12EU TINYINT			= 0,
    @transids_12EU	VARCHAR(4000)	= '',-- for custom delete 12EU
    @IP				VARCHAR(15)		= '',
    @DelOption_MHC	TINYINT			= 0,
    @transids_MHC	VARCHAR(4000)	= '',-- for custom delete master MHC	    
    @SAFilter		TINYINT			= 0,
    @betcount		INT				= 0 OUTPUT
)
AS
/*
	Created: 20120829@Lukas
	Task: check data before deleting tickets
	DB: DBTRANSPOOL,  licensee's DB
	
	Revisions:
	
	Param explanation
*/
BEGIN
	SET NOCOUNT ON 
	
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S')
	BEGIN
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
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END

	----INSERT Deposit CUSTOMER	
	INSERT INTO @DepositCust (custid, username)
	SELECT INF.Custid, INF.username 
		FROM custinfo INF WITH(nolock) 
			INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
			WHERE INF.srecommend in (SELECT custid FROM Dep_CustSuper WITH (NOLOCK)) 
			AND INF.ROLEID = 1
			AND BD.betfrom IN ('D', 'M', 'E', 'L')
	

	----INSERT 12EU CUSTOMER
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
		WHERE 
		#BetDelete.betfrom IN ('D', 'M', 'E', 'L')
		AND CustID IN (SELECT CustID FROM @DepositCust)		
		and custid not in (SELECT custid FROM @12EUCust) --12EU        
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
			and (custid not in (SELECT custid FROM @12EUCust) --12EU			
			and custid not in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) --Betdaq
			and mrecommend not in (SELECT custid FROM @MasterMHC))							
	END


	--FOR Delete BetDaq(BQUS888,BQUSMLB,BQUSNBA,BQUS)
	IF @DelOption_BD = 0 or (@DelOption_BD=2 and @transids_BD='')
	BEGIN
		DELETE FROM #BetDelete 
		WHERE custid in (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
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
		DELETE FROM #BetDelete 
		WHERE custid in (SELECT custid FROM @12EUCust)
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
	
	SELECT @betcount = COUNT(1)
	FROM #BetDelete
	
	DROP TABLE #BetDelete
END


GO
GRANT EXECUTE ON [Acc_BettransDelSpecial_Checking_xtest] TO bodbAdminNet