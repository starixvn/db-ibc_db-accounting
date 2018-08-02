/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_StatementSel_UAT3]
	@fromdate	SMALLDATETIME,
	@todate		SMALLDATETIME,
	@custid		INT
AS

/*
	Created by:[Cody]
	Date: 20141219
	Task: get statement report
	DB: DBACC.bodb02
	Revisions:
		- 20150706@Sophia: Do not check ticket running of Metric gaming at bettrans table, because of the translog [#38789]
		- 20150727@Sophia: Apply Bettrade - exclude ticket Bettrade Comm (903) for Void/reject [#36905]
		- 20150831@Sophia: Apply Colossus Bets - Add Grand Prize [#42428] 
		- 20151019@Sophia: Apply AG Casino - Add table bettransLC [#43810]
						   Apply Metricgaming - Add table bettransRNG [#43810]
		- 20151113@Sophia: Change Sporttype of Microgaming RNG Casino [RedmineId: #46450]
		- 20151221@Sophia: Exclude Cockfighting from bettrans table in case there is running ticket on bettrans [Redmine: #48602]
		- 20160108@Sophia: Change request for Colossus bet [Redmin: #49967]
		- 20160108@Sophia: Apply MBC One RNG Casino [Redmine: #48285]	
		- 20160204@Sophia: Apply Cricket - betcount exclude bettype 500 [Redmine: #50028]
		- 20160216@Sophia: Apply Allbet [Redmine: #50588]		
		- 20160328@Sophia: Check status Of PayOutTrans, get status Completed and Expired [Redmine: #54643]
		- 20160412@Percy: support Voidbridge single wallet [Redmine: #55258]
		- 20160615@Viet: enhance for the case getting data for master level.
		- 20160620@Percy:
			1. move void/reject ticket on bettransRnG/LC for today and yesterday on Void/Reject column into Winloss column [RedmineID: #59366]
			2. enhance performance: using right index on bettrans, bettransRnG/LC, translog
		- 20160824@Lukas: restrict permission on some specific members
		- 20170323@Percy: Apply Cash Out [RedmineID: #72164]
		- 20171020@Percy: Get both waiting and running tickets on translog [RedmineID: #84692]
		- 20180710@Sophia: WC2018 - Workaround SP high CPU at bettransRNG block code (roleid = 3 & 4) [Redmine: #98039]
		- 20180712@Sophia: WC2018 - Revise all the Sp [Redmine: #98039]
*/
 
BEGIN
	SET NOCOUNT ON
	
	----Get Sport bettype Matrix------
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

	CREATE TABLE #Sportbettype (Bettype INT PRIMARY KEY, RefTable TINYINT)
	INSERT INTO #Sportbettype (Bettype, RefTable)
	SELECT DISTINCT Bettype, RefTable FROM dbo.f_SportbettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)
	WHERE RefTable <> 0 -- get bettype in translog, bettransRnG, bettransLC
	-- RefTable: 0-bettrans, 1-bettransRnG, 2-bettransLC, 3-translog
	
	CREATE TABLE #Data (
		winlostdate			SMALLDATETIME
		,Bettype			SMALLINT
		,StatusID			SMALLINT
		,IsOwner			BIT     DEFAULT 0		
		,Outstanding		MONEY	NULL
		,Turnover			MONEY	NULL
		,Winlost			MONEY	NULL
		,Comm				MONEY	NULL
		,BetCount			INT		DEFAULT 0
		,OwnerWinloss		MONEY	NULL
		
	)

	CREATE TABLE #rptStatementTable(
		winlostdate			SMALLDATETIME	
		,OpeningBalance		MONEY	NULL
		,VoidAmt			MONEY	NULL
		,Outstanding		MONEY	NULL
		,Turnover			MONEY	NULL
		,TransferAmt		MONEY	NULL
		,Winlost			MONEY	NULL
		,Comm				MONEY	NULL
		,ClosingBalance		MONEY	NULL
		,BetCount			INT		DEFAULT 0
		,TransCount			INT		DEFAULT 0
		,VoidCount			INT		DEFAULT 0
		,PayoutCount		INT		DEFAULT 0
		,GrandPrize			MONEY	NULL 
		,Balance			MONEY		
		,IsOpeningBalance	BIT		DEFAULT 0
	)
	
	IF @custid IN (7214059,7213826,7213962)
	BEGIN
		SELECT winlostdate, 0 as CustID,OpeningBalance,VoidAmt,Outstanding,Turnover,TransferAmt,Winlost,Comm ,ClosingBalance,GrandPrize
		FROM #rptStatementTable
		
		DROP TABLE #rptStatementTable
		RETURN 
	END
	
	DECLARE @CID INT -- to prevent bad parameter sniffing
	SELECT  @CID = @custid
	

	DECLARE @roleid INT
	SELECT  @roleid = roleid FROM dbo.customer WITH(NOLOCK) WHERE custid = @CID

	DECLARE @recommend TABLE (recommend INT, PRIMARY KEY (recommend)) -- to using index on recommend level master and super
	DECLARE @mrecommend TABLE (mrecommend INT, PRIMARY KEY (mrecommend)) -- to using index on custID level super

	IF @roleid IN (1,2) -- Agent, member
		INSERT INTO @recommend VALUES (@CustID)
	IF @roleid = 3 -- master
		INSERT INTO @recommend (recommend)
		SELECT custid FROM dbo.Customer WITH(NOLOCK) WHERE mrecommend = @CID AND roleid = 2
	ELSE IF @roleid = 4 --super
		INSERT INTO @recommend (recommend)
		SELECT custid FROM dbo.Customer WITH(NOLOCK) WHERE srecommend = @CID AND roleid = 2

		INSERT INTO @mrecommend (mrecommend)
		SELECT custid FROM dbo.Customer WITH(NOLOCK) WHERE srecommend = @CID AND roleid = 3
		UNION ALL
		SELECT @CID 


	DECLARE @i BIGINT = 10000000  -- use optimize for
	DECLARE @total MONEY = 0 -- to calculate OpeningBalance
	
	DECLARE @tbl TABLE(winlostdate SMALLDATETIME)	
	
	;WITH CTE_WinlostDate (winlostdate) AS
	(		
		SELECT @fromdate as winlostdate
		UNION ALL
		SELECT DATEADD(DAY, 1, winlostdate) as winlostdate
		FROM CTE_WinlostDate
		WHERE winlostdate < @Todate		
	)
	INSERT INTO @tbl (Winlostdate)
	SELECT Winlostdate FROM CTE_WinlostDate
	 
		
	DECLARE @yesterday SMALLDATETIME 
	SELECT  @yesterday =  CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
	

	-- I. Get all data
			
	-- Member: get all status of ticket
	IF @roleid = 1
	BEGIN
		-- I.1.1. Bettrans
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Outstanding, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate, bettype, StatusID, CASE WHEN bettype > 20000 THEN 1 ELSE 0 END AS IsOwner  
			,SUM(ABS(actual_stake)) as Outstanding
			,SUM( ABS(stake) ) AS Turnover
			,SUM(winlost - actual_stake) AS OwnerWinloss
			,SUM(winlost - actual_stake) AS winlost
			,SUM(playercomm) AS comm
			,COUNT(1) AS betcount		
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, bettype, stake, winlost, actual_stake, playercomm
					FROM dbo.bettrans bt WITH (NOLOCK)		-- use index = CUSTID					
					WHERE r.recommend = bt.custID
						AND winlostdate <= @todate					
					) b
		GROUP BY winlostdate, bettype, StatusID, CASE WHEN bettype > 20000 THEN 1 ELSE 0 END 
		OPTION (OPTIMIZE FOR (@i = 1))



		-- I.1.2. BettransLC
		INSERT INTO #Data (winlostdate ,bettype, StatusID, IsOwner, Outstanding, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate
			,- 1 as Bettype  --- Get a general bettype for BettransLC/BettransRNG
			,StatusID, 0 as IsOwner
			,SUM(ABS(actual_stake)) as Outstanding
			,SUM( ABS(stake) ) AS Turnover
			,0 AS OwnerWinloss
			,SUM(winlost - actual_stake) AS winlost
			,SUM(playercomm) AS comm
			,COUNT(1) AS betcount		
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, stake, winlost, actual_stake, playercomm
					FROM dbo.bettransLC bt WITH (NOLOCK)		-- use index = CUSTID					
					WHERE r.recommend = bt.custID
						AND winlostdate <= @todate	
						AND winlostdate >= @yesterday				
					) b
		GROUP BY winlostdate, StatusID
		OPTION (OPTIMIZE FOR (@i = 1))

 
		
		-- I.1.3. BettransRNG
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Outstanding, Turnover,OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate
			,- 1 as Bettype  --- Get a general bettype for BettransLC/BettransRNG
			, StatusID, 0 as IsOwner
			,SUM(ABS(actual_stake)) as Outstanding
			,SUM( ABS(stake) ) AS Turnover
			,0 AS OwnerWinloss
			,SUM(winlost - actual_stake) AS winlost
			,SUM(playercomm) AS comm
			,COUNT(1) AS betcount
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, stake, winlost, actual_stake, playercomm
					FROM dbo.bettransRNG bt WITH (NOLOCK)		-- use index = CUSTID					
					WHERE r.recommend = bt.custID
						AND winlostdate <= @todate	
						AND winlostdate >= @yesterday				
					) b
		GROUP BY winlostdate, StatusID
		OPTION (OPTIMIZE FOR (@i = 1))
	
	END
	-- End Member --
		
	-- Agent --
	IF @roleid = 2
	BEGIN 
		-- I.2.1. Bettrans (downline and itsefl): Exclude ticket running, waiting, Void, reject
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate, bettype, StatusID, CASE WHEN recommend = @CID THEN 1 ELSE 0 END as IsOwner
			,SUM( ABS(stake) ) AS Turnover
			,SUM(winlost - actual_stake) AS OwnerWinloss
			,SUM(awinlost) AS winlost
			,SUM(comm - playercomm) AS comm
			,COUNT(1) AS betcount
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, bettype, stake, winlost, actual_stake, awinlost, comm, playercomm
					FROM dbo.bettrans bt WITH (NOLOCK)		-- use index = IX_recommend					
					WHERE r.recommend = bt.recommend
						AND winlostdate <= @todate
						AND winlostdate >= @yesterday				
						AND StatusID NOT IN (0,1)
					) b
		GROUP BY winlostdate, bettype, StatusID, CASE WHEN recommend = @CID THEN 1 ELSE 0 END 
		OPTION (OPTIMIZE FOR (@i = 1), HASH GROUP)


		 
		-- I.2.2. BettransLC:  Exclude ticket running, waiting 
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
			SELECT
			winlostdate 
			,-1 as bettype  --- Get a general bettype for BettransLC/BettransRNG
			,StatusID
			,0 as IsOwner
			,SUM(ABS(stake)) AS Turnover
			,0 AS OwnerWinloss
			,SUM(awinlost) AS winlost
			,SUM(comm - playercomm) AS comm
			,COUNT(1) AS betcount 
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, stake, awinlost, comm, playercomm
					FROM dbo.bettransLC bt WITH (NOLOCK)		-- use index = IX_recommend					
					WHERE r.recommend = bt.recommend
						AND winlostdate <= @todate
						AND winlostdate >= @yesterday				
						AND StatusID NOT IN (0,1)
					) b
		GROUP BY winlostdate, StatusID
		OPTION (OPTIMIZE FOR (@i = 1))
		

		-- I.2.3. BettransRNG: Exclude ticket running, waiting 
		INSERT INTO #Data (winlostdate, Bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)	
		SELECT
			winlostdate 
			,-1 as bettype  --- Get a general bettype for BettransLC/BettransRNG
			,StatusID
			,0 as IsOwner
			,SUM(ABS(stake)) AS Turnover
			,0 AS OwnerWinloss
			,SUM(awinlost) AS winlost
			,SUM(comm - playercomm) AS comm
			,COUNT(1) AS betcount 
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, stake, awinlost, comm, playercomm
					FROM dbo.bettransRNG bt WITH (NOLOCK)		-- use index = IX_recommend					
					WHERE r.recommend = bt.recommend
						AND winlostdate <= @todate
						AND winlostdate >= @yesterday				
						AND StatusID NOT IN (0,1)
					) b
		GROUP BY winlostdate, StatusID
		OPTION (OPTIMIZE FOR (@i = 1))

	END
	-- End Agent --
		
	-- Master
	IF @roleid = 3
	BEGIN
		
		-- I.3.1. Bettrans (downline):  Exclude ticket running, waiting, Void, reject
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate, bettype, StatusID, 0 as IsOwner
			,SUM(ABS(stake)) AS Turnover
			,0 AS OwnerWinloss
			,SUM(mwinlost) AS winlost
			,SUM(acomm - comm) AS comm
			,COUNT(1) AS betcount
		FROM @recommend r
		CROSS APPLY  ( 	
					SELECT TOP (@i) winlostdate, bettype, StatusID, stake, mwinlost, acomm, comm
					FROM dbo.bettrans bt WITH(NOLOCK) -- use index on custID
					WHERE	bt.recommend = r.recommend		
							AND winlostdate <= @todate 
							AND StatusID NOT IN (0,1,102,103)
				) b
		GROUP BY winlostdate, bettype, StatusID
		OPTION (OPTIMIZE FOR (@i = 1), HASH GROUP)
			 

		-- I.3.1b bettrans (itself, always is transfer & Openning BL & Sum tickets)
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			Winlostdate, bettype
			,131 as StatusID		 --- get a general StatusId	
			, 1 as IsOwner           --- master only
			,0 AS Turnover
			,SUM(winlost - actual_stake) AS OwnerWinloss
			,0 AS winlost
			,0 AS comm
			,COUNT(1) AS betcount
		FROM dbo.bettrans bt WITH (NOLOCK)	--- Use index on custID		
		WHERE CustID = @CID
			  AND Bettype >= 19999
			  AND winlostdate <= @todate	
		GROUP BY Winlostdate, bettype 
		
		-- I.3.2. BettransLC:  Exclude ticket running, waiting 	
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate
			,- 1 as Bettype  --- Get a general bettype for BettransLC/BettransRNG
			,StatusID
			,0 as IsOwner
			,SUM(ABS(stake)) AS Turnover
			,0 AS OwnerWinloss
			,SUM(mwinlost) AS winlost
			,SUM(acomm - comm) AS comm
			,COUNT(1) AS betcount 
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, stake, mwinlost, acomm, comm
					FROM dbo.bettransLC bt WITH (NOLOCK)	-- use index = IX_recommend						
					WHERE r.recommend = bt.recommend
						AND winlostdate <= @todate
						AND winlostdate >= @yesterday				
						AND StatusID NOT IN (0,1)
					) b
		GROUP BY winlostdate, StatusID
		OPTION (OPTIMIZE FOR (@i = 1))

		-- I.3.3. BettransRNG:  Exclude ticket running, waiting 
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate 
			,-1 as bettype  --- Get a general bettype for BettransLC/BettransRNG
			,StatusID
			,0 as IsOwner
			,SUM(ABS(stake)) AS Turnover
			,0 AS OwnerWinloss
			,SUM(mwinlost) AS winlost
			,SUM(acomm - comm) AS comm
			,COUNT(1) AS betcount 
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, stake, mwinlost, acomm, comm
					FROM dbo.bettransRNG bt WITH (NOLOCK)		-- use index = IX_recommend					
					WHERE r.recommend = bt.recommend
						AND winlostdate <= @todate
						AND winlostdate >= @yesterday				
						AND StatusID NOT IN (0,1)
					) b
		GROUP BY winlostdate, StatusID
		OPTION (OPTIMIZE FOR (@i = 1))

	END
	-- End Master --
		
	-- Super --
	IF @roleid = 4
	BEGIN		
		-- I.4.1 bettrans (Downline):  Exclude ticket running, waiting, Void, reject
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT 
			winlostdate, bettype, StatusID, 0 as IsOwner --- (Downline)
			,SUM(ABS(stake)) AS Turnover
			,0 AS OwnerWinloss
			,SUM(swinlost) AS winlost
			,SUM(scomm - acomm) AS comm
			,COUNT(1) AS betcount
		FROM @recommend r
		CROSS APPLY  ( 	
					SELECT TOP (@i) winlostdate, bettype, StatusID, stake, swinlost, scomm, acomm
					FROM dbo.bettrans bt WITH(NOLOCK) -- use index = IX_recommend
					WHERE	bt.recommend = r.recommend		
							AND winlostdate <= @todate 
							AND StatusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
				) b
		GROUP BY winlostdate, bettype, StatusID
		OPTION (OPTIMIZE FOR (@i = 1), HASH GROUP)	


		-- I.4.1b bettrans (Super and master level - always is transfer & SUM & Opening BL tickets)		
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			Winlostdate, bettype
			, 131 as StatusID  ---  get a general StatusId
			, IsOwner     --- (Super = 1 , Master = 0)
			,SUM(ABS(stake)) AS Turnover
			,SUM(winlost - actual_stake) AS OwnerWinloss
			,SUM(swinlost) AS winlost
			,SUM(scomm - acomm) AS comm
			,COUNT(1) AS betcount
		FROM @mrecommend m 
		CROSS APPLY (	SELECT TOP (@i) Winlostdate, bettype, CASE WHEN srecommend = CustID THEN 1 ELSE 0 END as IsOwner,
								stake, winlost, actual_stake, swinlost, scomm, acomm
						FROM dbo.bettrans bt WITH (NOLOCK) --- Use index CustID						
						WHERE m.mrecommend = bt.custid 
							AND bettype >= 19999
							AND winlostdate <= @todate
					) b
		GROUP BY Winlostdate, bettype, IsOwner
		OPTION (OPTIMIZE FOR (@i = 1))
		 
		
		-- I.4.2. BettransLC:  Exclude ticket running, waiting 
		INSERT INTO #Data (winlostdate, bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate
			,-1 AS bettype  --- Get a general bettype for BettransLC/BettransRNG
			,StatusID
			,0 as IsOwner  --- downline only
			,SUM(ABS(stake)) AS Turnover
			,0 AS OwnerWinloss
			,SUM(swinlost) AS winlost
			,SUM(scomm - acomm) AS comm
			,COUNT(1) AS betcount 
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, stake, swinlost, scomm, acomm
					FROM dbo.bettransLC bt WITH (NOLOCK)		-- use index = IX_recommend					
					WHERE r.recommend = bt.recommend
						AND winlostdate <= @todate
						AND winlostdate >= @yesterday				
						AND StatusID NOT IN (0,1)
					) b
		GROUP BY winlostdate, StatusID
		OPTION (OPTIMIZE FOR (@i = 1))

				
		-- I.4.3. BettransRNG:  Exclude ticket running, waiting	
		INSERT INTO #Data (winlostdate, Bettype, StatusID, IsOwner, Turnover, OwnerWinloss, Winlost, Comm, BetCount)
		SELECT
			winlostdate
			,-1 AS Bettype --- Get a general bettype for BettransLC/BettransRNG
			,StatusID
			,0 as IsOwner  --- downline only
			,SUM(ABS(stake)) AS Turnover
			,0 AS OwnerWinloss
			,SUM(swinlost) AS winlost
			,SUM(scomm - acomm) AS comm
			,COUNT(1) AS betcount 
		FROM @recommend r
		CROSS APPLY (
					SELECT TOP (@i) winlostdate, StatusID, stake, swinlost, scomm, acomm
					FROM dbo.bettransRNG bt WITH (NOLOCK)		-- use index = IX_recommend					
					WHERE r.recommend = bt.recommend
						AND winlostdate <= @todate
						AND winlostdate >= @yesterday				
						AND StatusID NOT IN (0,1)
					) b
		GROUP BY winlostdate, StatusID
		OPTION (OPTIMIZE FOR (@i = 1))
						
	END
	-- End Super --


	CREATE CLUSTERED INDEX IX_Data ON #Data (Bettype, WinlostDate, StatusID)

	-- II. Calculate data
	-- II.1 Get Winloss  
	-- @roleid IN (1,2,3,4)
	BEGIN		
		; WITH CTE_Winloss (winlostdate, Turnover, winlost, comm, betcount) AS
		(			
			SELECT
				winlostdate
				,SUM(CASE WHEN statusID NOT IN (101,102,103) THEN Turnover ELSE 0 END) AS Turnover
				,SUM(winlost) AS winlost
				,SUM(comm) AS comm
				,SUM(CASE WHEN bt.bettype = 500 THEN 0 ELSE betcount END) AS betcount
			FROM #Data bt			
			WHERE   bt.winlostdate BETWEEN @fromdate AND @todate
				AND bt.statusID NOT IN (0,1) 
				AND bt.bettype <= 19999  
						
				AND (  
						bt.bettype = -1	  --- BettransRNG/LC table group		
						OR 
						(    --- bettrans table group
							bt.bettype <> -1 AND bt.statusID NOT IN (102,101)
							AND NOT EXISTS (SELECT 1 FROM #Sportbettype s WHERE s.Bettype = bt.bettype AND s.RefTable <> 3 AND bt.winlostdate >= @yesterday) -- exclude running tickets on bettransRnG/LC								
						)				
					)
			GROUP BY winlostdate			
			
			) 
		INSERT INTO #rptStatementTable (winlostdate, Turnover, Winlost, Comm, BetCount)
		SELECT winlostdate,
			SUM (Turnover) as Turnover,
			SUM (Winlost) as Winlost,
			SUM (Comm) as Comm,
			SUM (BetCount) as BetCount
		FROM CTE_Winloss
		GROUP BY winlostdate	
	END 

	-- II. Get more Info for RoleID = 1 
	IF @RoleID = 1
	BEGIN			
		-- 2: Void/ Cancelled Bet - statusID = 101, 102
			---- 2.1 bettrans
			INSERT INTO #rptStatementTable (winlostdate, VoidAmt, VoidCount)
			SELECT 
				winlostdate
				,SUM(Turnover) AS VoidAmt
				,SUM(BetCount) AS VoidCount
			FROM #Data bt  				
			WHERE  bt.bettype <> -1      ---- bettrans table group
				AND bt.bettype NOT IN (903, 500, 913, 914)
				AND bt.bettype <= 19000
				AND bt.statusID IN (101, 102) -- 'VOID','REJECT'				
				AND bt.winlostdate BETWEEN @fromdate AND @todate		 
			    AND NOT EXISTS ( SELECT 1 FROM #Sportbettype s WHERE s.Bettype = bt.bettype and reftable <> 3) -- exclude running tickets on bettransRnG/LC
			GROUP BY winlostdate
		
			---- 2.2 bettransRnG/LC: no calculate statusID 101, 102 today, yesterday on column Void/Reject

			
		-- 3: Get outstanding
			---- 3.1 bettrans
			INSERT INTO #rptStatementTable (winlostdate, Outstanding, BetCount)
			SELECT 
				winlostdate
				,SUM(Outstanding) AS Outstanding
				,SUM(CASE WHEN bt.bettype = 500 THEN 0 ELSE BetCount END) AS BetCount
			FROM #Data bt
			WHERE bt.bettype <> -1      ---- bettrans table group
				AND bt.bettype <= 19000
				AND bt.statusID IN (0, 1) -- 'runing','waiting'				
				AND bt.winlostdate BETWEEN @fromdate AND @todate			
				AND NOT EXISTS (SELECT 1 FROM #Sportbettype s WHERE s.bettype = bt.bettype) -- exclude running tickets on bettransRnG/LC, translog
			GROUP BY winlostdate
			
			---- 3.2 translog
			INSERT INTO #rptStatementTable (winlostdate, Outstanding, BetCount)
			SELECT 
				winlostdate
				,SUM(actual_stake) AS Outstanding
				,COUNT(1) AS BetCount
			FROM dbo.translog WITH(NOLOCK)   
			WHERE
				winlostdate BETWEEN @fromdate AND @todate 
				AND custid = @CID  
				AND statusID IN (0, 1)
			GROUP BY winlostdate
	
			---- 3.3 bettransLC/bettransRNG
			INSERT INTO #rptStatementTable (winlostdate, Outstanding, BetCount)
			SELECT 
				winlostdate	
				,SUM(Outstanding) AS Outstanding
				,SUM(BetCount) AS BetCount
			FROM #Data  
			WHERE bettype = -1      ---- bettransRNG/LC table group
				AND statusID IN (0, 1) -- 'runing','waiting'
				AND winlostdate BETWEEN @fromdate AND @todate		
			GROUP BY winlostdate								

		-- 5: Grand Prize
			INSERT INTO #rptStatementTable (winlostdate, GrandPrize, PayoutCount)
			SELECT
				winlostdate
				,SUM(WinAmount) AS GrandPrize
				,COUNT (1) AS PayoutCount
			FROM dbo.PayoutTrans WITH(NOLOCK) 
			WHERE
				winlostdate BETWEEN @fromdate AND @todate
				AND custid = @CID						
				AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'
			GROUP BY winlostdate
		END
	  
	
	-- III. Get Openning Balance ----	
	-- @roleid IN (1,2,3,4)
	BEGIN
		;WITH CTE_Balance (winlostdate, Balance) AS
		(			
			SELECT
				CASE WHEN winlostdate < @fromdate THEN @fromdate ELSE DATEADD(DAY, 1, winlostdate) END AS winlostdate,
				SUM(CASE WHEN IsOwner = 1 THEN OwnerWinloss ELSE winlost + comm END) AS OpeningBalance
			FROM #Data bt  				
			WHERE statusID NOT IN (0, 1)
				AND winlostdate < @todate
				AND ( 
						bt.Bettype = -1
						OR (bt.Bettype <> -1 
							AND NOT EXISTS ( SELECT 1 FROM #Sportbettype s WHERE s.Bettype = bt.bettype AND s.RefTable <> 3  AND bt.winlostdate >= @yesterday) -- exclude tickets on bettransRnG/LC today, yesterday
							)
					)				
			GROUP BY CASE WHEN winlostdate < @fromdate THEN @fromdate ELSE DATEADD(DAY, 1, winlostdate) END

		)
		INSERT INTO #rptStatementTable (winlostdate, Balance, IsOpeningBalance)
		SELECT
			tmp.winlostdate,
			SUM(ISNULL(Balance, 0)),
			1
		FROM
			@tbl tmp
			LEFT JOIN CTE_Balance cb ON tmp.winlostdate = cb.winlostdate
		GROUP BY tmp.winlostdate
		ORDER BY winlostdate 	

		 
				
		/*Calculate Opening Balance*/
		SELECT @total = 0
		UPDATE #rptStatementTable
		SET OpeningBalance = @total, @total = @total + Balance -- running total
		WHERE IsOpeningBalance = 1

		DELETE #rptStatementTable
		WHERE winlostdate < (SELECT MIN(winlostdate) FROM #rptStatementTable WHERE OpeningBalance <> 0 AND IsOpeningBalance = 1)
			AND IsOpeningBalance = 1 
		/*End Calculate Opening Balance*/
	END

	-- IV. Transfer tickets	
	INSERT INTO #rptStatementTable (winlostdate, TransferAmt, TransCount)
	SELECT 
		winlostdate
		,SUM(OwnerWinloss) AS TransferAmt
		,SUM(BetCount) AS TransCount
	FROM #Data bt  
	WHERE  bettype > 20000
		AND bettype NOT IN (23001,23002,23101,23102,23201,23202)
		AND winlostdate BETWEEN @fromdate AND @todate
		AND IsOwner = 1
		AND Bettype <> -1  
	GROUP BY winlostdate
			
			 
	-- V. Show statement report
	SELECT 
		winlostdate
		,@CID AS CustID
		,SUM(ISNULL(OpeningBalance, 0)) AS [OpeningBalance]
		,SUM(Voidamt) AS [VoidAmt]
		,SUM(Outstanding) AS [Outstanding]
		,SUM(CASE WHEN BetCount > 0 THEN Turnover ELSE NULL END) AS [Turnover]
		,SUM(TransferAmt) AS [TransferAmt]
		,SUM(CASE WHEN BetCount > 0 THEN Winlost ELSE NULL END) AS [Winlost]
		,SUM(CASE WHEN BetCount > 0 THEN Comm ELSE NULL END) AS [Comm]
		,SUM(ISNULL(OpeningBalance, 0) + ISNULL([Winlost], 0) + ISNULL([Comm], 0) + ISNULL([TransferAmt], 0)) AS ClosingBalance
		,SUM(GrandPrize) AS GrandPrize
	FROM #rptStatementTable
	GROUP BY winlostdate
	HAVING
		SUM(BetCount) <> 0 
		OR SUM(VoidCount) <> 0 
		OR SUM(TransCount) <> 0
		OR SUM(PayoutCount) <> 0

	DROP TABLE #rptStatementTable
	DROP TABLE #Sportbettype
	DROP TABLE #Data 
END

GO 