ALTER PROCEDURE [dbo].[Acc_BettransDelSpecialDel_MixParlay]
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
    @reason NVARCHAR(500)='',
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT	    
AS
/*
	Created by: 
	Date: 
	Task: Delete transaction of mix parlay bet in bettransm
	DB: DBTXN/bodb02
	Original: 
	
	Revisions:
		- 20110906@Elly: include waiting status (=1)	
		- 20110907@Elly: remove updating void combination parlay tickets in BetParlayDetail
		- 20110909@Elly: change permission name	
		- 20110922@Tom: Add new bettypes 30, apply new bet type 1st correct score on Sport Books
				Replace parameter input @betteam4 => @betteam430
		- 20110929@Tom: Email notification for BEST-ODDs's UUS.
		- 20111006@Sophia: Add new parametter @Type, @livehomescore, @liveawayscore tp filter by livehomescore and liveawayscore
		- 20111019@Viet: update bettransm.winlostdate once deleting ticket
		- 20111026@Henry: add new deposit sites: SilverGoose8, Vwin, Galaxy, SunGame (change from Suncity)
		- 20111115@Sophia:  Add new parametter @transdate to filter by Live score
							Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'
		- 20111201@Henry: Change Galaxy to Tycoon
		- 20111219@Sophia: Send mail to internal when Currency is UUS, not to care the site anymore				 
		- 20111221@Sophia: When checking Permission to delete tickets, not to check username anymore.
		- 20111220@Lukas:
					- move backup tickets to zzzbettransm (instead zzzbettrans)	
					- Add more bettype: system parlay
		- 20120131@Henry: Change Sungame username prefix
		- 20120309@Sophia: Change param @transdate to @FromTransdate and @ToTransdate
		- 20120509@Henry: get deposit super from Dep_CustSuper instead of table Customer (exclude 12Bet)
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype, f_GetChoice for odds, Oddstype, betteam
		- 20120711@Sophia:	. Always insert custID into temp table @DepositCust, @12EUCust, @MasterMHC, not to check condition before insert. 
							. Optimize code of send mail for Deposit and 12EU
							. Add condition 'L' in betfrom to check Deposit
		- 20120913@Sophia: Check for concurrent running
		- 20130128@Elodie: Change link server DB03 to DBPOLICY
		- 20130526@Johnson: Add param @reason to log the reason delete bets
		- 20131108@Elodie: Splitting bodb02 into CustDB (call Customer, CustInfo from CustDB by link database)						   
		- 20131210@Kathy: Using Dep_CustSuper table to find deposit ticket instead of betfrom in ('D', 'M', 'E', 'L') [Redmine:#9321]
		 
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
	
	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDeleteMixParlay]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	IF NOT EXISTS (SELECT 1
		FROM CustDB.dbo.customer WITH (NOLOCK)
		WHERE	customer.userpwd = @UserPwd
			AND custid = @UserID
			AND roleid>=5)
	BEGIN
		SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' for Mix Parlay Special Delete reason: ' + @reason
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
			
	IF EXISTS(SELECT 1 FROM dbo.match WITH(NOLOCK) WHERE matchid=@matchid AND eventstatus='completed')
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can not delete completed match.'
		RETURN
	END
	
		
---- Check for concurrent running
	IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
	BEGIN
		SELECT @ErrCode = 102
		SELECT @ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'
		RETURN
	END
	ELSE 
	BEGIN
		UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = '1'
		WHERE VName = 'isCalculatingParlay'
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
		 INNER JOIN CustDB.dbo.customer AS c WITH(NOLOCK) ON c.custid=b.custid		
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
		FROM		CustDB.dbo.custinfo C (nolock) 
		INNER JOIN	#REF R 
				ON	C.custid = R.custid 
		WHERE C.srecommend in (
			SELECT custid FROM CustDB.dbo.Dep_CustSuper WITH (NOLOCK)
			--WHERE site <> '12Bet'
			/*
			SELECT custid FROM dbo.customer(nolock) WHERE UserName like 'MS88Super%' AND roleid=4 --mansion88
			UNION ALL
			SELECT custid FROM dbo.customer(nolock) WHERE username like 'ALogSuper%' AND roleid=4 --Alog
			UNION ALL
			SELECT custid FROM dbo.customer(nolock) WHERE username like 'DELASuper%' AND roleid=4 -- dela
			UNION ALL
			SELECT custid FROM dbo.customer(nolock) WHERE username like 'SPONSuper%' AND roleid=4 --spondemo
			UNION ALL
			SELECT custid FROM dbo.customer(nolock) WHERE username like 'TLCSuper%' AND roleid=4 --tlc
			UNION ALL
			SELECT custid FROM dbo.customer(nolock) WHERE username like 'Z88Super%' AND roleid=4 --zzun88
			UNION ALL
			SELECT custid FROM dbo.customer(nolock) WHERE username like 'MFSuper%' AND roleid=4 -- mayfair
			UNION ALL
			SELECT custid FROM dbo.customer(nolock) WHERE username like 'SUGSuper%' AND roleid=4 -- SunGame   
			UNION ALL
			SELECT custid FROM dbo.customer(nolock) WHERE UserName like 'BEZBETSuper%' AND roleid=4 --BEZBET
			UNION ALL
			SELECT custid FROM dbo.customer(nolock)  WHERE UserName like 'HAIFASuper%' and roleid=4 --HAIFA
			UNION All
			SELECT Custid FROM dbo.customer (nolock) WHERE UserName like 'BODOGSuper%' AND ROLEID=4 --BODOG
			UNION ALL
			SELECT Custid FROM dbo.customer (nolock) WHERE UserName like 'SG8Super%' AND ROLEID=4 --SILVERGOOSE8
			UNION ALL
			SELECT Custid FROM dbo.customer (nolock) WHERE UserName like 'TycoonSuper%' AND ROLEID=4 --Tycoon
			UNION ALL
			SELECT Custid FROM dbo.customer (nolock) WHERE UserName like 'VwinSuper%' AND ROLEID=4 --Vwin		
			*/
		) AND C.roleid = 1
		 -- AND R.betfrom IN ('D', 'M', 'E', 'L') 
	--END 
		
	----INSERT 12EU CUSTOMER
	--IF NOT (@DelOption_12EU = 0 OR (@DelOption_12EU=2 AND @transids_12EU=''))
	--BEGIN
		INSERT INTO @12EUCust (custid,username)
		SELECT		C.custid,C.username 
		FROM		CustDB.dbo.customer C WITH (nolock)
		INNER JOIN	#REF R 
				ON	C.custid = R.custid
		WHERE		C.username = '12EU'
	--END 

	--INSERT UUS  CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT		C.custid, C.username 
	FROM		CustDB.dbo.custinfo C WITH (nolock) 
	INNER JOIN	#REF R 
			ON	C.custid = R.custid
	WHERE C.srecommend in (
		SELECT custid FROM CustDB.dbo.customer (nolock) Where CURRENCY = 20 and roleid = 4
	) and C.roleid = 1
	
	
	--INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	INSERT INTO @RealCurrCust (CustID, username)
	SELECT		INF.custid, INF.username 
	FROM		CustDB.dbo.custinfo INF WITH (NOLOCK) 
	INNER JOIN	#REF BD ON INF.Custid = BD.Custid 
	WHERE		INF.srecommend IN( SELECT custid FROM CustDB.dbo.customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
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
<<<<<<< HEAD
		WHERE r.srecommend not IN (SELECT custid FROM CustDB.dbo.Dep_CustSuper with(NOLOCK) ) --r.betfrom NOT IN ('D', 'M', 'E', 'L')
=======
		WHERE r.srecommend not IN (SELECT custid FROM custDB.dbo.Dep_CustSuper with(NOLOCK) ) --r.betfrom NOT IN ('D', 'M', 'E', 'L')
>>>>>>> 0448880ae30cafa75d9183b60b49146b0d1b12ae
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
<<<<<<< HEAD
		WHERE r.srecommend not IN (SELECT custid FROM CustDB.dbo.Dep_CustSuper with(NOLOCK) ) --r.betfrom NOT IN ('D', 'M', 'E', 'L')
=======
		WHERE r.srecommend not IN (SELECT custid FROM custDB.dbo.Dep_CustSuper with(NOLOCK) ) --r.betfrom NOT IN ('D', 'M', 'E', 'L')
>>>>>>> 0448880ae30cafa75d9183b60b49146b0d1b12ae
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
<<<<<<< HEAD
		WHERE r.srecommend IN (SELECT custid FROM CustDB.dbo.Dep_CustSuper with(NOLOCK) ) --r.betfrom IN ('D', 'M', 'E', 'L')
=======
		WHERE r.srecommend IN (SELECT custid FROM custDB.dbo.Dep_CustSuper with(NOLOCK) ) --r.betfrom IN ('D', 'M', 'E', 'L')
>>>>>>> 0448880ae30cafa75d9183b60b49146b0d1b12ae
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
<<<<<<< HEAD
		WHERE r.srecommend IN (SELECT custid FROM CustDB.dbo.Dep_CustSuper with(NOLOCK) ) --r.betfrom IN ('D', 'M', 'E', 'L')
=======
		WHERE r.srecommend IN (SELECT custid FROM custDB.dbo.Dep_CustSuper with(NOLOCK) ) --r.betfrom IN ('D', 'M', 'E', 'L')
>>>>>>> 0448880ae30cafa75d9183b60b49146b0d1b12ae
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

------------------***** Begin Special Delete *****------------------
	
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
	FROM dbo.bettransm AS b WITH (nolock)
		INNER JOIN #Ref AS r WITH(NOLOCK) ON r.transid=b.transid --AND r.refno=b.refno AND b.matchid = @matchid			
	/*
		END -  ADD MORE LOG IN ZZZBETTRANS FOR VIEWING LOG TW SITE
	*/
	
	--BackUp tickets of bettransm
	INSERT INTO	zzzbettransm
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM dbo.bettransm AS b WITH (nolock)
		INNER JOIN #Ref AS r WITH(NOLOCK) ON r.transid=b.transid --AND r.refno=b.refno AND b.matchid = @matchid			

	declare @matchdate datetime, @match_tmp varchar(20), @rowcount INT, @step INT, @transid_tmp VARCHAR(2000)

	select	@matchdate = eventdate,
			@match_tmp = CONVERT(VARCHAR(20),matchid),
			@step = 0
	from match with(nolock) where matchid = @matchid
		
		
	--- void selection
	DECLARE @transtbl TABLE (id INT IDENTITY, transid BIGINT)
	INSERT INTO @transtbl (transid)
				SELECT transid
				FROM #Ref
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

	IF EXISTS (	SELECT TOP 1 1
				FROM bettrans b WITH(NOLOCK) 
					INNER JOIN #Ref r ON b.refno = r.refno
				WHERE b.matchid = 29 AND b.bettype = 29
			   ) 
	BEGIN
		EXEC dbo.Admin_Calculate_29_PreCal @matchids = @match_tmp
		EXEC dbo.Admin_Calculate_29 @matchids = @match_tmp, @matchdate = @matchdate

		---********* Calculate balance at bettrans table********---
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
				INNER JOIN #Ref r ON b.refno = r.refno
			WHERE b.matchid = 29 AND b.bettype = 29
			GROUP BY b.CustID		

		--Settlement System parlay (changed balance)
		EXEC dbo.Admin_Calculate_29_Summary 

		--Get data after update
			INSERT INTO #AfterUpd (custid, balance)
			SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
			FROM	bettrans b WITH (NOLOCK)
				INNER JOIN #Ref r ON b.refno = r.refno
			WHERE b.matchid = 29 AND b.bettype = 29
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
			
			DELETE #BeforeUpd
			DELETE #AfterUpd
	---********* End of calculate balance at bettrans table********---

	END


	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' for Mix Parlay Special Delete' + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + ' reason: ' + @reason
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
	
	

	
	--after delete, return all deleted tickets with additional information for mailing
	IF EXISTS (SELECT 1 FROM #Ref WITH(NOLOCK))
	BEGIN		
		IF EXISTS(SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
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
			b.transid,
			r.transid AS SubTransID,
			r.refno,
			b.username,
			b.custid,
			b.transdate,			
			cr.username as creator,	
			b.stake,
			b.winlost-b.actual_stake AS winlost,
			b.odds,   
			b.OddsType, 	
			b.bettype,
			b.status,
			b.spositiontaking,
			b.mpositiontaking,
			b.apositiontaking,				
			b.currency,			
			b.mrecommend,			
			--case when betfrom IN ('D', 'M', 'E') then 1 else 0 end as IsDeposit
			r.bettype AS choice_bettype
			,m.homeid
			,m.awayid
			,r.hdp1 AS choice_hdp1
			,r.hdp2 AS choice_hdp2
			,r.odds AS choice_odds
			,r.betteam
			,r.livehomescore
			,r.liveawayscore
			,r.liveindicator
			,m.leagueid
			,m.sporttype
			,m.isNeutral
			,m.matchID
			,m.matchCode
			,ag.site
	FROM dbo.bettrans AS b with (NOLOCK)
		INNER JOIN #Ref AS r WITH(NOLOCK) ON b.refno=r.refno AND b.matchid IN (9,29) AND b.bettype IN (9,29)
		INNER JOIN dbo.match AS m WITH(NOLOCK) ON m.matchid=@MatchID
		--INNER JOIN CustDB.dbo.customer AS ag with (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN CustDB.dbo.customer AS cr with (NOLOCK) ON cr.custid = b.creator
		INNER JOIN CustDB.dbo.customer ag WITH (NOLOCK) ON ag.custid=b.recommend	
	WHERE	(b.betid = 0 OR b.betid IS NULL)
			AND 
			(	b.custid IN (SELECT custid FROM @12EUCust)  
				OR b.custid IN (SELECT custid FROM @DepositCust)
			)
--			or b.custid IN (SELECT custid FROM @DepositCust)			
--		  )
	ORDER BY b.transid
	
	END	
	
	SELECT b.transid,
		r.custid, mem.UserName AS CustUserName,
		r.recommend, ag.UserName AS AgUserName,
		r.mrecommend, mag.UserName AS MagUserName,
		r.srecommend, sag.Username AS SagUserName
	FROM dbo.bettrans AS b WITH(NOLOCK) 
		INNER JOIN #Ref AS r WITH(nolock) ON b.refno=r.refno AND b.matchid IN (9,29) AND b.bettype IN (9,29)
		INNER JOIN CustDB.dbo.custinfo mem (nolock) ON r.custid     = mem.custid
		INNER JOIN CustDB.dbo.custinfo ag  (nolock) ON r.recommend  = ag.custid
		INNER JOIN CustDB.dbo.custinfo mag (nolock) ON r.mrecommend = mag.custid
		INNER JOIN CustDB.dbo.custinfo sag (nolock) ON r.srecommend = sag.custid
	
-----BEGIN : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam' / OR Currency is UUS
		SELECT
			b.transid,
			r.transid AS SubTransID,
			r.refno,
			b.username,
			b.custid,
			b.transdate,			
			cr.username as creator,	
			b.stake,
			b.winlost-b.actual_stake AS winlost,
			b.odds,   
			b.OddsType, 
			b.bettype,			
			b.status,
			b.spositiontaking,
			b.mpositiontaking,
			b.apositiontaking,				
			b.currency,			
			b.mrecommend,			
			--case when betfrom IN ('D', 'M', 'E') then 1 else 0 end as IsDeposit
			r.bettype AS choice_bettype
			,m.homeid
			,m.awayid
			,r.hdp1 AS choice_hdp1
			,r.hdp2 AS choice_hdp2
			,r.odds AS choice_odds
			,r.betteam
			,r.livehomescore
			,r.liveawayscore
			,r.liveindicator
			,m.leagueid
			,m.sporttype
			,m.isNeutral
			,m.matchID
			,m.matchCode
			,ag.site 
			,1 as isInternalMail 
	FROM dbo.bettrans AS b with (NOLOCK)
		INNER JOIN #Ref AS r WITH(NOLOCK) ON b.refno=r.refno AND b.matchid IN (9,29) AND b.bettype IN (9,29)
		INNER JOIN dbo.match AS m WITH(NOLOCK) ON m.matchid=@MatchID
		INNER JOIN CustDB.dbo.customer AS cr with (NOLOCK) ON cr.custid = b.creator
		INNER JOIN CustDB.dbo.customer ag WITH (NOLOCK) ON ag.custid=b.recommend	
	WHERE	(b.betid = 0 OR b.betid IS NULL)
			AND 
				( b.custid IN (SELECT custid FROM @RealCurrCust)	
				  OR b.custid IN (SELECT custid FROM @UUSCust)
				 )	
	ORDER BY b.transid
	
-----END : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS
	
	DROP TABLE #Ref	
	
	-----
	UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
	SET		VValue = '0'
    WHERE	VName = 'isCalculatingParlay'	
			
	SET NOCOUNT OFF
END

<<<<<<< HEAD
=======


>>>>>>> 0448880ae30cafa75d9183b60b49146b0d1b12ae
GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecialDel_MixParlay] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecialDel_MixParlay] TO [vnteam] AS [dbo]