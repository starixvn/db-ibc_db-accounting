USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_SpecialDelete_VoidByCurrency_Update]    Script Date: 04/25/2016 09:31:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_SpecialDelete_VoidByCurrency_Update] 
	@MatchID		INT,
	@LicenseeNames	VARCHAR(MAX),
	@TicketType		VARCHAR(100),
	@CurrencyIDs	VARCHAR(100),
	@MainTransIDs	VARCHAR(MAX),		

	@UserID			INT,  
	@UserName		NVARCHAR(50),
	@UserPassword   NVARCHAR(50),  
	@Reason			NVARCHAR(500) = '',  
	@IP				VARCHAR(15)  = '',  
	@ErrMsg			NVARCHAR(200) = '' OUTPUT,  
	@ErrCode		INT    = 0  OUTPUT  
AS
/*
	Created: Kent
	Date: 20161201
	DB: DBTXN/bodb02

	Revisions: 		
		- 20161201@Kent: Search sportbook tickets by crrency to void [Redmine:#67987]
	
	Param's Explanation:			
			- @TicketType:
			'All': All
			'SingleTicket': Single ticket
			'ParlayTicket': Parlay ticket
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MBCGroup_Name VARCHAR(50) = 'MBC Group'
		  , @VoidPatchSize INT = 100	
	
	DECLARE @LogData					NVARCHAR(500) = ''
		  , @GeneralErrMsg				NVARCHAR(200) = 'Unable to void these tickets'
		  , @CurrencyCodes				VARCHAR(MAX)
		  , @UserIDNotInITGroup			BIT
		  , @SearchSingle				BIT
		  , @CountSingle				INT
		  , @SearchParlay				BIT
		  , @CountParlay				INT
		  
	DECLARE @isExistOutright 			BIT = 0
		  , @isExistMatch				BIT = 0
		  , @KeyID						INT
		  
		  , @AvaiableProcess_Single		BIT
		  , @ErrCode_Concurrent_Single	INT = 0 
		  , @ErrMsg_Concurrent_Single	NVARCHAR(200) = '' 		  
		  , @isLocked_Single			BIT	= 0
		  
		  , @AvaiableProcess_Parlay		BIT
		  , @ErrCode_Concurrent_Parlay	INT = 0 
		  , @ErrMsg_Concurrent_Parlay	NVARCHAR(200) = '' 		  
		  , @isLocked_Parlay			BIT	= 0
	
	DECLARE @tblMainTransIds TABLE (transid BIGINT)
	
	DECLARE @tblBeforeBalance TABLE (custid INT PRIMARY KEY, balance MONEY)
	
	DECLARE @tblAfterBalance TABLE (custid INT PRIMARY KEY, balance MONEY)
	
	DECLARE @tblDebitPending TVP_BalanceList
	
	DECLARE @tblCreditPending TVP_BalanceList
	
	CREATE TABLE #SpecialDeleteBets (
			Stake				MONEY,
			AwayId				INT,
			BetCheck			NVARCHAR(50),
			BetId				BIGINT DEFAULT (0),
			BetTeam				NVARCHAR(10),
			BetType				SMALLINT,
			CurrencyCode		NVARCHAR(50),
			Creator				INT,
			creatorName			VARCHAR(30),
			Hdp1				SMALLMONEY,
			Hdp2				SMALLMONEY,
			HomeId				INT,
			IsLiveIndicator		BIT, 
			IsNeutral			BIT, 
			IsSecondAcceptFlag	BIT, 
			LiveAwayScore		SMALLINT,
			LiveHomeScore		SMALLINT,
			Odds				MONEY,
			IsMixParlay			BIT,
			OddsType			INT,
			RefNo				BIGINT,
			SportType			SMALLINT,
			Status				NVARCHAR(10),
			TransDate			DATETIME,
			TransDesc			NVARCHAR(1000),
			TransId				BIGINT,
			UserName			VARCHAR(30),
			WinLost				MONEY,
			site				VARCHAR(10),
			betfrom				NVARCHAR(1),
			srecommend			INT,
			custid				INT,
			balance				MONEY,
			
			SubTransId			BIGINT,
			SubBetCheck			NVARCHAR(50),
			SubBetTeam			NVARCHAR(10),
			SubBetType			SMALLINT,
			SubHdp1				SMALLMONEY,
			SubHdp2				SMALLMONEY,
			SubOdds				MONEY
		)
		
	SELECT  s.Stake,
			s.AwayId,
			s.BetCheck,
			s.BetId,
			s.BetTeam,
			s.BetType,
			s.CurrencyCode,
			s.creatorName AS Creator,
			s.Hdp1,
			s.Hdp2,
			s.HomeId,
			s.IsLiveIndicator,
			s.IsNeutral,
			s.IsSecondAcceptFlag,
			s.LiveAwayScore,
			s.LiveHomeScore,
			s.Odds,
			s.IsMixParlay,
			s.OddsType,
			s.RefNo,
			s.SportType,
			s.Status,
			s.TransDate,
			s.TransDesc,
			s.TransId,
			s.UserName,
			s.WinLost,
			CAST('' AS VARCHAR(50)) AS EmailGroup,
			
			s.SubTransId,
			s.SubBetCheck,
			s.SubBetTeam,
			s.SubBetType,
			s.SubHdp1,
			s.SubHdp2,
			s.SubOdds,
			
			CAST(1 AS BIT) AS IsCsd,
			CAST(1 AS BIT) AS IsItQa,
			CAST(1 AS BIT) AS IsItSupport,
			s.betfrom,
			CURRENT_TIMESTAMP AS [DateTime]
				INTO #t
	FROM #SpecialDeleteBets s
	WHERE 1 = 0	
	
	CREATE TABLE #t_LicenseeNames(LicenseeName VARCHAR(100))
	CREATE CLUSTERED INDEX t_IDX_LicenseeNames_LicenseeName ON #t_LicenseeNames(LicenseeName)	
	
	CREATE TABLE #t_exchanges(exchangeid INT, currency NVARCHAR(50))
	
	CREATE TABLE #tblMatchProcess (matchid INT, KeyID TINYINT)
	
	-------> Parse @LicenseeNames	
	INSERT INTO #t_LicenseeNames(LicenseeName)
	SELECT ss.val
	FROM dbo.strSplit(@LicenseeNames, ',') ss
	
	DELETE FROM #t_LicenseeNames WHERE LicenseeName = @MBCGroup_Name
	IF @@ROWCOUNT > 0
		INSERT INTO #t_LicenseeNames(LicenseeName)
		SELECT [site]
		FROM DBCUST.CUSTDB.dbo.Site WITH(NOLOCK) 
		WHERE isLicensee = 0
		  and SpecialGroup = 0 
		  and isActive = 1	
	
	-------> Parse @CurrencyIDs	  
	INSERT INTO #t_exchanges(exchangeid, currency)
	SELECT e.exchangeid, e.currency
	FROM dbo.strSplit(@CurrencyIDs, ',') ss
		 INNER JOIN CustDB.dbo.exchange e WITH(NOLOCK)
				 ON CAST(ss.val AS INT) = e.exchangeid	
				 
	-------> Parse @MainTransIds
	INSERT INTO @tblMainTransIds(transid)
	SELECT ss.val AS transid
	FROM dbo.strSplit(@MainTransIds, ',') ss
	
	IF @@ROWCOUNT = 0
	BEGIN		
		SELECT @ErrCode = 99, @ErrMsg = 'No ticket found.'
		
		SELECT * FROM #t		
		
		RETURN
	END						 	  
		
	SELECT @SearchSingle = 0, @SearchParlay = 0
	IF @TicketType = 'All'
	BEGIN	
		SELECT @SearchSingle = 1, @SearchParlay = 1
		
		-------> Check concurrent single
		IF EXISTS(SELECT TOP 1 1 FROM #SpecialDeleteBets WHERE bettype = 10) -- bettype 10: outright
		BEGIN 	
			SELECT @KeyID 			= 2
				 , @isExistOutright 	= 1
				 , @isExistMatch		= 0
		END
		ELSE
		BEGIN 	
			SELECT @KeyID 			= 1
				 , @isExistOutright 	= 0
				 , @isExistMatch		= 1
		END
		
		INSERT INTO #tblMatchProcess (matchid, KeyID)
		SELECT @matchid AS matchid
			 , @KeyID 	AS KeyID
			 
		-- checking SD proccess
		EXEC dbo.NAP_Admin_CheckingProcess
			@isExistOutright 	= @isExistOutright
			, @isExistMatch		= @isExistMatch
			, @avaiableProcess 	= @AvaiableProcess_Single OUTPUT
			, @ErrCode			= @ErrCode_Concurrent_Single OUTPUT
			, @ErrMsg			= @ErrMsg_Concurrent_Single OUTPUT
		SET @isLocked_Single = 1			
			
		IF(@ErrCode_Concurrent_Single <> 0 OR @AvaiableProcess_Single = 0) 
		BEGIN
			SELECT * FROM #t			
			
			RETURN
		END	
		
		-------> Check concurrent parlay
		EXEC [dbo].[NAP_Admin_CheckingProcess]
			@IsExistParlay = 1			
		  , @IsReleased	= 0
		  , @AvaiableProcess = @AvaiableProcess_Parlay OUTPUT
		  , @ErrCode = @ErrCode_Concurrent_Parlay OUTPUT
		  , @ErrMsg	= @ErrMsg_Concurrent_Parlay OUTPUT	
		SET @isLocked_Parlay = 1
		
		IF (@ErrCode_Concurrent_Parlay <> 0 OR @AvaiableProcess_Parlay = 0)
		BEGIN	
			SELECT * FROM #t
			
			-------> Release process single
			EXEC dbo.NAP_Admin_CheckingProcess
				@isExistOutright 	= @isExistOutright
				, @isExistMatch		= @isExistMatch
				, @IsReleased		= 1				
						 
			RETURN		 
		END					 
	END
	ELSE IF @TicketType = 'SingleTicket'
	BEGIN
		SET @SearchSingle = 1
		
		-------> Check concurrent single
		IF EXISTS(SELECT TOP 1 1 FROM #SpecialDeleteBets WHERE bettype = 10) -- bettype 10: outright
		BEGIN 	
			SELECT @KeyID 			= 2
				 , @isExistOutright 	= 1
				 , @isExistMatch		= 0
		END
		ELSE
		BEGIN 	
			SELECT @KeyID 			= 1
				 , @isExistOutright 	= 0
				 , @isExistMatch		= 1
		END
		
		INSERT INTO #tblMatchProcess (matchid, KeyID)
		SELECT @matchid AS matchid
			 , @KeyID 	AS KeyID
			 
		-- checking SD proccess
		EXEC dbo.NAP_Admin_CheckingProcess
			@isExistOutright 	= @isExistOutright
			, @isExistMatch		= @isExistMatch
			, @avaiableProcess 	= @AvaiableProcess_Single OUTPUT
			, @ErrCode			= @ErrCode_Concurrent_Single OUTPUT
			, @ErrMsg			= @ErrMsg_Concurrent_Single OUTPUT
		SET @isLocked_Single = 1			
			
		IF(@ErrCode_Concurrent_Single <> 0 OR @AvaiableProcess_Single = 0) 
		BEGIN
			SELECT * FROM #t			
			
			RETURN
		END
	END
	ELSE IF @TicketType = 'ParlayTicket'
	BEGIN
		SET @SearchParlay = 1
		
		-------> Check concurrent parlay
		EXEC [dbo].[NAP_Admin_CheckingProcess]
			@IsExistParlay = 1			
		  , @IsReleased	= 0
		  , @AvaiableProcess = @AvaiableProcess_Parlay OUTPUT
		  , @ErrCode = @ErrCode_Concurrent_Parlay OUTPUT
		  , @ErrMsg	= @ErrMsg_Concurrent_Parlay OUTPUT	
		SET @isLocked_Parlay = 1
		
		IF (@ErrCode_Concurrent_Parlay <> 0 OR @AvaiableProcess_Parlay = 0)
		BEGIN	
			SELECT * FROM #t										
						 
			RETURN		 
		END
	END
	ELSE
	BEGIN	
		SELECT * FROM #t										
					 
		RETURN		 
	END	
	
	-------> Build @LogData
	SET @CurrencyCodes = ''
	SELECT @CurrencyCodes = @CurrencyCodes
							+ CASE WHEN @CurrencyCodes <> '' THEN ',' ELSE '' END
							+ currency
	FROM #t_exchanges
	SET @LogData = 'Void currency transaction for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' for ' + @LicenseeNames + ' ' + @CurrencyCodes + ' IP=' + @IP + ' reason: ' + @Reason
	
	BEGIN TRY
		-------> Get tickets to void
		--> Get single tickets
		SET @CountSingle = 0
		IF @SearchSingle = 1
		BEGIN
			INSERT INTO #SpecialDeleteBets(
						Stake,
						AwayId,
						BetCheck,
						BetId,
						BetTeam,
						BetType,
						CurrencyCode,
						Creator,
						creatorName,
						Hdp1,
						Hdp2,
						HomeId,
						IsLiveIndicator,
						IsNeutral,
						IsSecondAcceptFlag,
						LiveAwayScore,
						LiveHomeScore,
						Odds,
						IsMixParlay,
						OddsType,
						RefNo,
						SportType,
						Status,
						TransDate,
						TransDesc,
						TransId,
						UserName,
						WinLost,
						site,
						betfrom,
						srecommend,
						custid,
						balance,
						
						SubTransId,
						SubBetCheck,
						SubBetTeam,
						SubBetType,
						SubHdp1,
						SubHdp2,
						SubOdds		
					)
			SELECT 	b.Stake,
					m.AwayId,
					b.BetCheck,
					b.BetId,
					b.BetTeam,
					b.BetType,
					te.currency AS CurrencyCode,
					b.Creator,
					cr.username AS creatorName,
					b.Hdp1,
					b.Hdp2,
					m.HomeId,
					b.LiveIndicator AS IsLiveIndicator,
					ISNULL(m.IsNeutral, CONVERT(BIT, 0)) AS IsNeutral,
					b.SecAcceptFlag AS IsSecondAcceptFlag,
					b.LiveAwayScore,
					b.LiveHomeScore,
					b.Odds,
					0 AS IsMixParlay,
					b.OddsType,
					b.RefNo,
					m.SportType,
					b.STATUS,
					b.TransDate,
					b.TransDesc,
					b.TransId,
					b.UserName,
					b.WinLost,
					c.site,
					b.betfrom,
					b.srecommend,
					b.custid,
					b.winlost - b.actual_stake + b.playercomm AS balance,
					
					NULL AS SubTransId,
					NULL AS SubBetCheck,
					NULL AS SubBetTeam,
					NULL AS SubBetType,
					NULL AS SubHdp1,
					NULL AS SubHdp2,
					NULL AS SubOdds		
			FROM @tblMainTransIds t
				 INNER JOIN bettrans b WITH (NOLOCK)
						 ON t.transid = b.transid
				 INNER JOIN #t_exchanges te WITH (NOLOCK)
						 ON b.currency = te.exchangeid -- filter for @CurrencyCodes			 
				 INNER JOIN CUSTDB.dbo.Customer c WITH (NOLOCK)
						 ON b.recommend = c.custid
				 INNER JOIN #t_LicenseeNames tl WITH (NOLOCK)
						 ON tl.LicenseeName = c.site -- filter for @LicenseeIDs	
				 INNER JOIN match m WITH (NOLOCK)
						 ON b.matchid = m.matchid
				 INNER JOIN CustDB.dbo.custInfo cr WITH(NOLOCK)
						 ON b.creator = cr.custid							 		 
			WHERE m.sporttype BETWEEN 1 AND 99 -- sportbook only			
				AND b.bettype NOT IN (9, 29) -- single
				AND b.bettype < 19001
				AND b.bettype NOT IN (31,32,33,71,72,73)	-- NOT IN [Racing, Casino]
				AND b.bettype NOT BETWEEN 801 AND 806-- MG
				AND b.bettype NOT BETWEEN 901 AND 910 -- BT subticket
				AND b.bettype NOT BETWEEN 1501 AND 1599	-- NOT IN Keno
				AND NOT (b.Username like '%bettrade%' AND b.betdaqid = 0) -- current owner is not member bettrade			
				AND b.statusID NOT IN (101, 102) -- reject, void
				AND b.betfrom <> 'P' -- exclude phone betting
				AND b.matchid = @MatchID -- filer for @MatchID
		
			SET @CountSingle = @@ROWCOUNT
		END
		
		--> Get parlay tickets
		SET @CountParlay = 0
		IF @SearchParlay = 1
		BEGIN
			INSERT INTO #SpecialDeleteBets(
						Stake,
						AwayId,
						BetCheck,
						BetId,
						BetTeam,
						BetType,
						CurrencyCode,
						Creator,
						creatorName,
						Hdp1,
						Hdp2,
						HomeId,
						IsLiveIndicator,
						IsNeutral,
						IsSecondAcceptFlag,
						LiveAwayScore,
						LiveHomeScore,
						Odds,
						IsMixParlay,
						OddsType,
						RefNo,
						SportType,
						Status,
						TransDate,
						TransDesc,
						TransId,
						UserName,
						WinLost,
						site,
						betfrom,
						srecommend,
						custid,
						balance,
						
						SubTransId,
						SubBetCheck,
						SubBetTeam,
						SubBetType,
						SubHdp1,
						SubHdp2,
						SubOdds		
					)
			SELECT  main.Stake,
					m.AwayId,
					main.BetCheck,
					main.BetId,
					main.BetTeam,
					main.BetType,
					te.currency AS CurrencyCode,
					main.Creator,
					cr.username AS creatorName,
					main.Hdp1,
					main.Hdp2,
					m.HomeId,
					main.LiveIndicator AS IsLiveIndicator,
					ISNULL(m.IsNeutral, CONVERT(BIT, 0)) AS IsNeutral,
					main.SecAcceptFlag AS IsSecondAcceptFlag,
					main.LiveAwayScore,
					main.LiveHomeScore,
					main.Odds,
					1 AS IsMixParlay,
					main.OddsType,
					main.RefNo,
					m.SportType,
					main.status AS Status,
					main.transdate AS TransDate,
					main.transdesc AS TransDesc,
					main.transid AS TransId,
					main.UserName,
					main.winlost AS WinLost,
					c.site,
					main.betfrom,
					main.srecommend,
					main.custid,
					main.winlost - main.actual_stake + main.playercomm AS balance,
					
					sub.transid AS SubTransId,
					sub.betcheck AS SubBetCheck,
					sub.betteam AS SubBetTeam,
					sub.bettype AS SubBetType,
					sub.hdp1 AS SubHdp1,
					sub.hdp2 AS SubHdp2,
					sub.odds AS SubOdds		
			FROM @tblMainTransIds t
				 INNER JOIN bettrans main WITH (NOLOCK)
						 ON t.transid = main.transid
				 INNER JOIN #t_exchanges te WITH (NOLOCK)
						 ON main.currency = te.exchangeid  -- filter for @CurrencyCodes
				 INNER JOIN CUSTDB.dbo.Customer c WITH (NOLOCK)
						 ON main.recommend = c.custid
				 INNER JOIN #t_LicenseeNames tl1 WITH (NOLOCK)
						 ON tl1.LicenseeName = c.site -- filter for @LicenseeIDs
				 INNER JOIN CustDB.dbo.custInfo cr WITH(NOLOCK)
						 ON main.creator = cr.custid						 			 				 					 
				 
				 INNER JOIN dbo.bettransm sub WITH (NOLOCK)	
						 ON main.refno = sub.refno
				 INNER JOIN match m WITH (NOLOCK)
						 ON sub.matchid = m.matchid
			WHERE main.matchid IN (9, 29) AND main.bettype IN (9, 29) -- parlay
				AND main.statusID NOT IN (101, 102) -- reject, void
				AND NOT (main.Username like '%bettrade%' AND main.betdaqid = 0) -- current owner is not member bettrade
				AND main.betfrom <> 'P' -- exclude phone betting
				
				AND m.sporttype BETWEEN 1 AND 99 -- sportbook only						
				AND sub.bettype < 19001
				AND sub.bettype NOT IN (31,32,33,71,72,73)	-- NOT IN [Racing, Casino]
				AND sub.bettype NOT BETWEEN 801 AND 806-- MG
				AND sub.bettype NOT BETWEEN 901 AND 910 -- BT subticket
				AND sub.bettype NOT BETWEEN 1501 AND 1599	-- NOT IN Keno
				AND sub.matchid = @matchid -- filer for @MatchID
				AND sub.statusID NOT IN (101, 102) -- reject, void
				AND sub.betfrom <> 'P' -- exclude phone betting
			
			SET @CountParlay = @@ROWCOUNT
		END
		
		IF @CountSingle + @CountParlay = 0
		BEGIN
			-------> Release process
			--> Release single
			IF @isLocked_Single = 1
				EXEC dbo.NAP_Admin_CheckingProcess
					@isExistOutright 	= @isExistOutright
					, @isExistMatch		= @isExistMatch
					, @IsReleased		= 1
			--> Release parlay
			IF @isLocked_Parlay = 1
				EXEC dbo.NAP_Admin_CheckingProcess  
					@isExistParlay  = 1  
					, @IsReleased  = 1
					
			SELECT @ErrCode = 99, @ErrMsg = 'No ticket found.'
			
			SELECT * FROM #t		
			
			RETURN
		END
		
		-------> Insert backups	
		--> backups for single
		INSERT INTO zzzbettrans (transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,
					winlost,livehomescore,liveawayscore,liveindicator,betteam,creator, refno, 
					winlostdate,betfrom,betcheck,checktime,matchid, bettype)
		SELECT  main.transid, main.custid, CURRENT_TIMESTAMP, main.oddsid, main.hdp1, main.hdp2, main.odds, main.stake, main.status, 
				main.winlost, main.livehomescore, main.liveawayscore, main.liveindicator, main.betteam, main.creator , main.refno, 
				main.winlostdate, main.betfrom, main.betcheck, main.checktime, main.matchid, main.bettype
		FROM dbo.bettrans main WITH (nolock)
			 INNER JOIN #SpecialDeleteBets tmpmain 
				ON	main.transid = tmpmain.transid
		WHERE tmpmain.IsMixParlay = 0
		
		--> backups for parlay	
		-- BackUp bettransm tickets into zzzbettrans  
		INSERT INTO zzzbettrans (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status,   
				winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno,   
				winlostdate, betfrom, betcheck, checktime, matchid, bettype
		)  
		SELECT	b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status,  
				b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno,  
				b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype  
		FROM	dbo.bettransm AS b WITH (nolock)  
			INNER JOIN #SpecialDeleteBets AS r 
				ON	r.transid=b.transid 
		WHERE r.IsMixParlay = 1  

		--BackUp tickets of bettransm  
		INSERT INTO zzzbettransm (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status,   
				 winlost, livehomescore, liveawayscore, liveINdicator, betteam, creator , refno,   
				 winlostdate, betfrom, betcheck, checktime, matchid, bettype)  
		SELECT	b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status,   
				b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno,   
				b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype  
		FROM	dbo.bettransm AS b WITH (nolock)  
			INNER JOIN #SpecialDeleteBets AS r 
				ON	r.transid=b.transid
		WHERE r.IsMixParlay = 1				
		
		-------> Capture before balance
		INSERT INTO @tblBeforeBalance (custid, balance)
		SELECT	t.custid
				,SUM(t.balance) balance
		FROM #SpecialDeleteBets t					
		GROUP BY t.CustID
		
		-------> update status for tickets to void
		--> update status for single
		UPDATE	main
			SET winlost		= main.actual_stake
				,ruben			= 1
				,statuswinlost	= 6
				,creator		= @UserID
				,awinlost		= 0
				,mwinlost		= 0
				,swinlost		= 0
				,playercomm		= 0
				,comm			= 0
				,acomm			= 0
				,scomm			= 0
				,statusID		= 102       
				,status			= 'VOID'
		FROM	dbo.bettrans main WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #SpecialDeleteBets tmpmain
				ON	main.transid = tmpmain.transid					
					AND main.matchid = @matchid	
					AND tmpmain.IsMixParlay = 0
		
		--> update status for parlay
		DECLARE @matchdate		DATETIME
				,@match_tmp		VARCHAR(20)
				,@rowcount		INT
				,@step			INT
				,@transid_tmp	VARCHAR(2000) 		
		DECLARE @transids_29 VARCHAR(MAX) = ''  
			  , @refnos_29  VARCHAR(MAX) = '' 
			  
		DECLARE @transtbl TABLE (id INT IDENTITY, transid BIGINT)			  			  		   		
		
		SELECT	@matchdate = eventdate,  
				@match_tmp = CONVERT(VARCHAR(20),matchid),  
				@step = 0  
		FROM	match WITH(NOLOCK)   
		WHERE	matchid = @matchid
		
		SELECT	@transids_29 = @transids_29 + CONVERT(VARCHAR(20), transid) + ','
			  , @refnos_29 = @refnos_29 + CONVERT(VARCHAR(20), refno) + '|' + CONVERT(VARCHAR(20), transid) + ','  
		FROM	#SpecialDeleteBets  
		WHERE IsMixParlay = 1
		
		INSERT INTO @transtbl (transid)  
		SELECT	SubTransId  
		FROM	#SpecialDeleteBets
		WHERE IsMixParlay = 1
		
		-- update bettransm,BetParlayDetail		
		SELECT @rowcount = @@ROWCOUNT 
		
		WHILE @step < @rowcount  
		BEGIN  
			SET @transid_tmp = ''  

			SELECT	@transid_tmp  = @transid_tmp + CONVERT(VARCHAR(20),transid)  + ','   
			FROM	@transtbl  
			WHERE	id > @step 
					AND id <= @step + @VoidPatchSize  
			 
			SET @step = @step + @VoidPatchSize  

			EXEC dbo.NAP_Admin_Calculate_MP_broker @matchid = @matchId  
			,@fth = 0  
			,@fta = 0  
			,@hth = 0  
			,@hta = 0  
			,@matchdate = @matchdate  
			,@mode = 'VOID'  
			,@VoidTransID = @transid_tmp  
			,@UserId = @UserId  
			 
		END
		
		-- call pre-cal-29: update BetParlayResult		  
		EXEC dbo.NAP_Admin_Calculate_MP_broker   
			@matchid = @matchid  
			,@matchdate = @matchdate  
			,@strXML = @transids_29  
			,@mode  = 'PRECAL-29'
		
		-- call cal_29: update bettrans
		EXEC dbo.NAP_Admin_Calculate_MP_broker
			@matchdate = @MatchDate
			,@strXML	= @refnos_29  -- main transid + refno: refno|transid,refno|transid...
			,@mode		= '29' 
		
		-------> Capture after balance
		INSERT INTO @tblAfterBalance (custid, balance)
		SELECT	t.custid
				,SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM #SpecialDeleteBets t	
			INNER JOIN bettrans b WITH (NOLOCK) 
				ON t.transid = b.transid		
		GROUP BY t.CustID				
		
		-------> Update balance for members	
		--> update credit balance of cust
		INSERT INTO @tblCreditPending (custID, balance)
		SELECT		a.custid, (a.balance - b.balance) AS Balance
		FROM		@tblBeforeBalance b
		INNER JOIN	@tblAfterBalance a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) > 0
				
		IF @@rowcount <> 0
			EXEC dbo.Dot_BalancePendingCreditIns 
				@BalancePending = @tblCreditPending
				,@Type			= 1 -- Sports		

		--> update dedit balance of cust
		INSERT INTO @tblDebitPending (custID, balance)
		SELECT		a.custid, ABS(a.balance - b.balance) AS Balance
		FROM		@tblBeforeBalance b
		INNER JOIN	@tblAfterBalance a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) < 0	
		
		IF @@rowcount <> 0
			EXEC dbo.Dot_BalancePendingDebitIns 
				@BalancePending = @tblDebitPending
				,@Type			= 1 -- Sports
		
		-------> Update odds
		UPDATE odds  
		SET hometotal = hometotal - (CASE WHEN b.betteam = 'h' THEN CASE WHEN abs(b.odds) > 1 THEN b.stake * e.actualrate * abs(b.odds) * (1 - b.tpositiontaking)  
					  ELSE b.stake * e.actualrate * (1 - b.tpositiontaking) END  
			   ELSE 0 END )  
		,awaytotal = awaytotal - (CASE WHEN b.betteam = 'a' THEN CASE WHEN abs(b.odds) > 1 THEN b.stake * e.actualrate * abs(b.odds) * (1 - b.tpositiontaking)  
					  ELSE b.stake * e.actualrate * (1 - b.tpositiontaking) END  
				ELSE 0 END)  
		FROM dbo.odds o WITH (ROWLOCK,UPDLOCK)  
			INNER JOIN dbo.bettrans b WITH (NOLOCK) 
				ON o.matchid = b.matchid 
				   AND o.oddsid = b.oddsid  
				   AND b.matchid = @MatchID			
			INNER JOIN CustDB.dbo.customer c WITH (NOLOCK) ON c.custid = b.custid  
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid	
		WHERE EXISTS ( 
				SELECT TOP 1 1   
				FROM #SpecialDeleteBets AS bd
				WHERE bd.TransID  = b.transid
					AND bd.Bettype NOT IN (9, 29)
					AND bd.Bettype NOT BETWEEN 801 AND 899 --Metric Gaming Super Live
					AND bd.Bettype NOT IN (901,902,903)  --BetTrade subtickets  
		   )  																			
		
		-------> write log		
		EXEC WriteLog_UserLog 
			 @UserId = @UserId,
			 @Doing = @LogData
			 
		-------> Data for sending mail
		SET @UserIDNotInITGroup = 0
		IF NOT EXISTS (SELECT TOP 1 1 
					   FROM DBPOLICY.bodb02.dbo.accCustomer_1 a 
					   WHERE a.GroupID = 1
				  		 AND a.custid = @UserID)
			SET @UserIDNotInITGroup = 1		
		SELECT  s.Stake,
				s.AwayId,
				s.BetCheck,
				s.BetId,
				s.BetTeam,
				s.BetType,
				s.CurrencyCode,
				s.creatorName AS Creator,
				s.Hdp1,
				s.Hdp2,
				s.HomeId,
				s.IsLiveIndicator,
				s.IsNeutral,
				s.IsSecondAcceptFlag,
				s.LiveAwayScore,
				s.LiveHomeScore,
				s.Odds,
				s.IsMixParlay,
				s.OddsType,
				s.RefNo,
				s.SportType,
				s.Status,
				s.TransDate,
				s.TransDesc,
				s.TransId,
				s.UserName,
				s.WinLost,
				CASE 
					WHEN s.custid IN (1077687,2331,115770,15523642,15042477,16041068,16041058) THEN 'Betfair' 
					ELSE s.site 
				END AS EmailGroup,
				
				s.SubTransId,
				s.SubBetCheck,
				s.SubBetTeam,
				s.SubBetType,
				s.SubHdp1,
				s.SubHdp2,
				s.SubOdds,
				
				CASE
					WHEN T2.a IS NOT NULL 
						 OR (T3.a IS NOT NULL 
							 AND @UserIDNotInITGroup = 1 -- Check UserID not in IT group
							)
								THEN CAST(1 AS BIT)
					ELSE CAST(0 AS BIT)
				END AS IsCsd,
				CASE
					WHEN T3.a IS NOT NULL 
						 AND @UserIDNotInITGroup = 0
								THEN CAST(1 AS BIT)
					ELSE CAST(0 AS BIT)
				END AS IsItQa,
				CASE
					WHEN T2.a IS NOT NULL 
						 AND @UserIDNotInITGroup = 0
								THEN CAST(1 AS BIT)
					ELSE CAST(0 AS BIT)							
				END AS IsItSupport,
				s.betfrom,
				CURRENT_TIMESTAMP AS [DateTime]
		FROM #SpecialDeleteBets s
			 OUTER APPLY (SELECT TOP 1 1 AS a
						  FROM CustDB.dbo.Customer c WITH(NOLOCK) 
						  WHERE c.currency <> 20 
							AND c.roleid = 4 
							AND c.custid = s.srecommend) AS T2
			 OUTER APPLY (SELECT TOP 1 1 AS a
						  FROM CustDB.dbo.Customer c WITH(NOLOCK) 
						  WHERE c.currency = 20 
							AND c.roleid = 4 
							AND c.custid = s.srecommend) AS T3		
	END TRY
	BEGIN CATCH
		-------> Release process
		--> Release single
		IF @isLocked_Single = 1
			EXEC dbo.NAP_Admin_CheckingProcess
				@isExistOutright 	= @isExistOutright
				, @isExistMatch		= @isExistMatch
				, @IsReleased		= 1
		--> Release parlay
		IF @isLocked_Parlay = 1
			EXEC dbo.NAP_Admin_CheckingProcess  
				@isExistParlay  = 1  
				, @IsReleased  = 1		  
	
		SELECT @ErrCode = 100,
				@ErrMsg = @GeneralErrMsg
				
		SELECT * FROM #t		
							
		RETURN				
	END CATCH
	
	-------> Release process
	--> Release single
	IF @isLocked_Single = 1
		EXEC dbo.NAP_Admin_CheckingProcess
			@isExistOutright 	= @isExistOutright
			, @isExistMatch		= @isExistMatch
			, @IsReleased		= 1
	--> Release parlay
	IF @isLocked_Parlay = 1
		EXEC dbo.NAP_Admin_CheckingProcess  
			@isExistParlay  = 1  
			, @IsReleased  = 1
			
	SET NOCOUNT OFF
END
GO

GRANT EXECUTE ON [dbo].[NAP_SpecialDelete_VoidByCurrency_Update]  TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialDelete_VoidByCurrency_Update]  TO [vnteam] AS [dbo]
GO
			