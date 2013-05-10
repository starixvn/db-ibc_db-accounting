

ALTER PROCEDURE [dbo].[Acc_BettransDelSpecialDel_MixParlay_Checking_xtest]
	@MatchID int,
	@Type smallint = 0, 	
    @livehomescore smallint = NULL,
    @liveawayscore smallint = NULL, 	
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@hdp smallmoney = 9999,	
	@bettypes varchar(128) = '',	
	@betteam1378 varchar(10) = 'ALL',
	@betteam515 varchar(10) = 'ALL',
	@betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
	@Language NVARCHAR(2) = 'E',
	@DelOption TINYINT = 0,
	@transids varchar(4000)='',
	@DelOption_D TINYINT = 0,
	@transids_D varchar(4000)='',
	@DelOption_BD TINYINT = 0,
    @transids_BD VARCHAR(4000) = '',-- for custom delete BetDaq
    @DelOption_12EU TINYINT = 0,
    @transids_12EU VARCHAR(4000) = '',-- for custom delete 12EU    
    @DelOption_MHC TINYINT = 0,
    @transids_MHC VARCHAR(4000)= '',-- for custom delete master MHC	  
    @UserID INT,
    @UserName NVARCHAR(50),
    @UserPwd NVARCHAR(50),
    @IP VARCHAR(15) = '',
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT,
    @betcount	INT = 0 OUTPUT
AS
/*
	Created: 20121002@Lukas	
	Task: check & count affected tickets
	DB: DBTRANS.BODB02
	Original: 
	
	Revisions:
		

	Param's Explanation: Special bet delete option
	
	@@DelOption = 0: No Delete (need to remove normal bets out of #BetDelete)
    @@DelOption = 1: Delete All (no need to remove normal bets out of s#BetDelete)
    @@DelOption = 2: Optional Delete (remove normal bets with option)
    
    @@DelOption_D = 0: No Delete (need to remove DepositBets out of #BetDelete)
    @@DelOption_D = 1: Delete All (no need to remove DepositBets out of #BetDelete)
    @@DelOption_D = 2: Optional Delete (remove DepositBets with option)

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
	SELECT @ErrCode = 0
				
	---- 'You can not delete completed match.' --> check on web	
			
	---- Check for concurrent running
	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
		BEGIN
			SELECT @ErrCode = 102
			SELECT @ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'
			RETURN
		END
	END
-----------	
									
	CREATE TABLE #Ref (--id int identity(1,1) primary key clustered 
						refno bigint 
						,transid int	
						,custid int	
						,srecommend int		
						,mrecommend int
						,recommend int
						,betfrom nvarchar(1)
						,bettype smallint						
						,hdp1 smallmoney
						,hdp2 smallmoney
						,odds smallmoney
						,betteam nvarchar(20)
						,livehomescore smallint
						,liveawayscore smallint
						,liveindicator bit						
						,org_betteam nvarchar(10)	
						,statusID int						
					)
	--CREATE TABLE #Currency (Refno bigint, CurrencyID tinyint,oddstype tinyint)
	DECLARE @12EUCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @DepositCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @MasterMHC TABLE (custid INT)

------------------***** Insert all data into #Ref *****------------------

	INSERT INTO #Ref (
						refno
						,transid
						,custid	
						,srecommend
						,mrecommend
						,recommend
						,betfrom
						,bettype
						,hdp1
						,hdp2
						,odds
						,betteam
						,livehomescore
						,liveawayscore
						,liveindicator
						,org_betteam
						,statusID
				)
	SELECT b.refno
		,b.transid
		,c.custid
		,c.srecommend
		,c.mrecommend
		,c.recommend
		,b.betfrom
		,b.bettype
		,b.hdp1
		,b.hdp2
		,b.odds
		,b.betteam		
		,b.livehomescore
		,b.liveawayscore
		,b.liveindicator
		,b.betteam		
		,b.statusID
	FROM dbo.bettransm AS b WITH(NOLOCK)		 
		 INNER JOIN dbo.customer AS c WITH(NOLOCK) ON c.custid=b.custid		
	WHERE b.matchid=@MatchID	
		AND CASE WHEN @Type = 2 THEN @Type ELSE b.liveindicator END = @Type
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @Type = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @Type = 1 THEN @liveawayscore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @Type = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @Type = 1 THEN @ToTransdate ELSE b.transdate END 


	CREATE CLUSTERED INDEX cl_Ref_refno ON #Ref(refno)
	CREATE NONCLUSTERED INDEX nl_Ref_StatusID ON #Ref(StatusID)
	CREATE NONCLUSTERED INDEX nl_Ref_bettype_org_betteam ON #Ref(bettype,org_betteam)
	
	
	--REMOVE REDUNDANT item
	DELETE #Ref
	WHERE statusID NOT IN (0,1,103)
	
	DELETE r
	FROM #Ref AS r 
		LEFT JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype
	WHERE bt.val IS NULL -- remove unselected bettypes
		
	IF @betteam1378<>'All'
		DELETE r
		FROM #Ref AS r 
			INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype
		WHERE r.bettype IN (1,3,7,8,2,12) AND (r.org_betteam<>@betteam1378)
	
	IF @betteam515<>'All'
		DELETE r
		FROM #Ref AS r 
			INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype
		WHERE r.bettype in (5,15) AND (r.org_betteam<>@betteam515)
	
	IF @hdp <> 9999
		DELETE r
		FROM #Ref AS r 
			INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype
		WHERE r.bettype IN (1,3,7,8) AND (hdp1<>@hdp-hdp2)			
		
	IF @betteam430=''	
		DELETE #Ref
		WHERE bettype IN (4,30) 
	ELSE IF @betteam430<> 'All'
		DELETE r
		FROM #Ref AS r
			LEFT JOIN dbo.strSplit(@betteam430,'^') AS b4 ON b4.val=r.org_betteam		
		WHERE (r.bettype IN (4,30) AND (b4.val IS NULL))			
	
	IF @betteam6=''
		DELETE #Ref
		WHERE bettype=6
	ELSE IF @betteam6<>'All'	
		DELETE r
		FROM #Ref AS r 	
			LEFT JOIN dbo.strSplit(@betteam6,'^') AS b6 ON b6.val=r.org_betteam		
		WHERE r.bettype=6 AND (b6.val IS NULL)
	
	IF @betteam14=''
		DELETE #Ref
		WHERE bettype=14
	ELSE IF @betteam14<>'All'	
		DELETE r
		FROM #Ref AS r 	
			LEFT JOIN dbo.strSplit(@betteam14,'^') AS b14 ON b14.val=r.org_betteam		
		WHERE r.bettype=14 AND (b14.val IS NULL)
	
	IF @betteam16=''
		DELETE #Ref
		WHERE bettype=16
	ELSE IF @betteam16<>'All'	
		DELETE r
		FROM #Ref AS r 	
			LEFT JOIN dbo.strSplit(@betteam16,'^') AS b16 ON b16.val=r.org_betteam		
		WHERE r.bettype=16 AND (b16.val IS NULL)
	
	CREATE NONCLUSTERED INDEX nl_Ref_custid_transid ON #Ref(custid,transid)
--FOR DELETE SECTION
	
	
	
----------------------------------------------------------------------------------------------
------------------***** Insert Custid of each type into its temp table *****------------------	

	----INSERT Deposit CUSTOMER
	--IF NOT (@DelOption_D = 0 OR (@DelOption_D=2 AND @transids_D=''))
	--BEGIN
		INSERT INTO @DepositCust (custid, username)
		SELECT		C.custid, C.username 
		FROM		dbo.custinfo C (nolock) 
		INNER JOIN	#REF R 
				ON	C.custid = R.custid 
		WHERE C.srecommend in (
			SELECT custid FROM Dep_CustSuper WITH (NOLOCK)			
		) AND C.roleid = 1
		  AND R.betfrom IN ('D', 'M', 'E', 'L') 
	--END 
		
	----INSERT 12EU CUSTOMER
	--IF NOT (@DelOption_12EU = 0 OR (@DelOption_12EU=2 AND @transids_12EU=''))
	--BEGIN
		INSERT INTO @12EUCust (custid,username)
		SELECT		C.custid,C.username 
		FROM		dbo.customer C WITH (nolock)
		INNER JOIN	#REF R 
				ON	C.custid = R.custid
		WHERE		C.username = '12EU'
	--END 

	--INSERT UUS  CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT		C.custid, C.username 
	FROM		custinfo C WITH (nolock) 
	INNER JOIN	#REF R 
			ON	C.custid = R.custid
	WHERE C.srecommend in (
		SELECT custid FROM customer (nolock) Where CURRENCY = 20 and roleid = 4
	) and C.roleid = 1
	
	
	--INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	INSERT INTO @RealCurrCust (CustID, username)
	SELECT		INF.custid, INF.username 
	FROM		custinfo INF WITH (NOLOCK) 
	INNER JOIN	#REF BD ON INF.Custid = BD.Custid 
	WHERE		INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
				AND INF.roleid = 1 
				AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')			
			
			
	---- INSERT MASTER MHC
	--IF NOT (@DelOption_MHC = 0 OR (@DelOption_MHC=2 AND @transids_MHC=''))
	--BEGIN	
	INSERT INTO @MasterMHC(custid)
	SELECT 105181
	union all
	SELECT 118473
	union all
	SELECT 105183
	--END 	

------------------***** End of insert Custid of each type into its temp table  *****------------------		

------------------***** Remove data no need to special delete out of #Ref *****------------------	
	
	--DELETE NORMAL TICKETS
	IF @DelOption = 0 OR (@DelOption=2 AND @transids='') --not delete any
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)
			LEFT JOIN @DepositCust AS d ON d.CustID = r.CustID
			LEFT JOIN @12EUCust AS c12 ON r.custid=c12.custid
			LEFT JOIN dbo.f_GetBetDaqCustomer(1) AS bd ON r.custid=bd.custid
			LEFT JOIN @MasterMHC AS m ON r.mrecommend=m.custid
		WHERE r.betfrom NOT IN ('D', 'M', 'E', 'L')
			AND d.custID IS NULL
			AND c12.custid IS NULL--not in
			AND bd.custid IS NULL--not in
			AND m.custid IS NULL--not in
			
	ELSE IF @DelOption=2 AND @transids<>''
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)		
			LEFT JOIN @DepositCust AS d ON d.CustID = r.CustID	
			LEFT JOIN @12EUCust AS c12 ON r.custid=c12.custid
			LEFT JOIN dbo.f_GetBetDaqCustomer(1) AS bd ON r.custid=bd.custid
			LEFT JOIN @MasterMHC AS m ON r.mrecommend=m.custid
			LEFT JOIN dbo.strSplit(@transids, ',') AS t ON t.val=r.transid
		WHERE r.betfrom NOT IN ('D', 'M', 'E', 'L')
			AND d.custID IS NULL
			AND c12.custid IS NULL--not in
			AND bd.custid IS NULL--not in
			AND m.custid IS NULL--not in
			AND t.val IS NULL--not in
			
	--DELETE DEPOSIT TICKETS
	IF @DelOption_D = 0 OR (@DelOption_D=2 AND @transids_D='') --not delete any
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)
			INNER JOIN @DepositCust AS d ON d.CustID = r.CustID
			LEFT JOIN @12EUCust AS c12 ON r.custid=c12.custid
			LEFT JOIN dbo.f_GetBetDaqCustomer(1) AS bd ON r.custid=bd.custid
			LEFT JOIN @MasterMHC AS m ON r.mrecommend=m.custid
		WHERE r.betfrom IN ('D', 'M', 'E', 'L')
			AND c12.custid IS NULL--not in
			AND bd.custid IS NULL--not in
			AND m.custid IS NULL--not in
			
	ELSE IF @DelOption_D=2 AND @transids_D<>''
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)	
			INNER JOIN @DepositCust AS d ON d.CustID = r.CustID		
			LEFT JOIN @12EUCust AS c12 ON r.custid=c12.custid
			LEFT JOIN dbo.f_GetBetDaqCustomer(1) AS bd ON r.custid=bd.custid
			LEFT JOIN @MasterMHC AS m ON r.mrecommend=m.custid
			LEFT JOIN dbo.strSplit(@transids_D, ',') AS t ON t.val=r.transid
		WHERE r.betfrom IN ('D', 'M', 'E', 'L')
			AND c12.custid IS NULL--not in
			AND bd.custid IS NULL--not in
			AND m.custid IS NULL--not in
			AND t.val IS NULL--not in
		
	--DELETE BetDaq TICKETS
	IF @DelOption_BD=0 OR (@DelOption_BD=2 AND @transids_BD='') --not delete any	
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)			
			INNER JOIN dbo.f_GetBetDaqCustomer(1) AS bd ON r.custid=bd.custid
					
	ELSE IF @DelOption_BD=2 AND @transids_BD<>''
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)			
			INNER JOIN dbo.f_GetBetDaqCustomer(1) AS bd ON r.custid=bd.custid
			LEFT JOIN dbo.strSplit(@transids_BD, ',') AS t ON t.val=r.transid
		WHERE t.val IS NULL --not in
	
	--DELETE 12EU TICKETS
	IF @DelOption_12EU=0 OR (@DelOption_12EU=2 AND @transids_12EU='') --not delete any
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)			
			INNER JOIN @12EUCust AS c12 ON r.custid=c12.custid
				
	ELSE IF @DelOption_12EU=2 AND @transids_12EU<>'' 
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)			
			INNER JOIN @12EUCust AS c12 ON r.custid=c12.custid
			LEFT JOIN dbo.strSplit(@transids_12EU, ',') AS t ON t.val=r.transid
		WHERE t.val IS NULL --not in
		
	--DELETE tickets of master MHCEU (105181), MHCRM (118473), MHCUS(105183)
	IF @DelOption_MHC=0 OR (@DelOption_MHC=2 AND @transids_MHC='') --not delete any
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)			
			INNER JOIN @MasterMHC AS m ON r.mrecommend=m.custid
		
	ELSE IF @DelOption_MHC=2 AND @transids_MHC<>'' 
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)			
			INNER JOIN @MasterMHC AS m ON r.mrecommend=m.custid
			LEFT JOIN dbo.strSplit(@transids_MHC, ',') AS t ON t.val=r.transid
		WHERE t.val IS NULL --not in
------------------***** End of Remove data no need to special delete out of #BetDelete  *****------------------

	SELECT @betcount = COUNT(1)	
	FROM #Ref

	DROP TABLE #Ref		

	SET NOCOUNT OFF
END



GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecialDel_MixParlay_Checking_xtest] TO [bodbAdminNet]
GO


