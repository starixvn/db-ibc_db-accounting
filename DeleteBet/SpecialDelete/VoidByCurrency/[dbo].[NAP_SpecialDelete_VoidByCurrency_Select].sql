USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_SpecialDelete_VoidByCurrency_Select]    Script Date: 04/25/2016 09:31:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_SpecialDelete_VoidByCurrency_Select] 
	@MatchID		INT,
	@LicenseeNames	VARCHAR(MAX),
	@TicketType		VARCHAR(100),
	@CurrencyIDs	VARCHAR(100)
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
	
	DECLARE @SearchSingle BIT
		  , @SearchParlay BIT
	
	CREATE TABLE #SpecialDeleteBets (
			Stake				MONEY,
			AwayId				INT,
			BetCheck			NVARCHAR(50),
			BetId				BIGINT DEFAULT (0),
			BetTeam				NVARCHAR(10),
			BetType				SMALLINT,
			CurrencyCode		NVARCHAR(50),
			Creator				INT,
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
			GroupName			VARCHAR(10),
			
			SubTransId			BIGINT,
			SubBetCheck			NVARCHAR(50),
			SubBetTeam			NVARCHAR(10),
			SubBetType			SMALLINT,
			SubHdp1				SMALLMONEY,
			SubHdp2				SMALLMONEY,
			SubOdds				MONEY
		)			
				
	CREATE TABLE #t_LicenseeNames(LicenseeName VARCHAR(100))
	CREATE CLUSTERED INDEX t_IDX_LicenseeNames_LicenseeName ON #t_LicenseeNames(LicenseeName)	
	
	CREATE TABLE #t_exchanges(exchangeid INT, currency NVARCHAR(50))
	
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
	
	INSERT INTO #t_exchanges(exchangeid, currency)
	SELECT e.exchangeid, e.currency
	FROM dbo.strSplit(@CurrencyIDs, ',') ss
		 INNER JOIN CustDB.dbo.exchange e WITH(NOLOCK)
				 ON CAST(ss.val AS INT) = e.exchangeid
	
	SELECT @SearchSingle = 0, @SearchParlay = 0
	IF @TicketType = 'All'	
		SELECT @SearchSingle = 1, @SearchParlay = 1
	ELSE IF @TicketType = 'SingleTicket'
		SET @SearchSingle = 1
	ELSE IF @TicketType = 'ParlayTicket'
		SET @SearchParlay = 1			   
	
	--> single
	IF @SearchSingle = 1
		INSERT INTO #SpecialDeleteBets(
					Stake,
					AwayId,
					BetCheck,
					BetId,
					BetTeam,
					BetType,
					CurrencyCode,
					Creator,
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
					GroupName,
					
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
				c.site AS GroupName,
				
				NULL AS SubTransId,
				NULL AS SubBetCheck,
				NULL AS SubBetTeam,
				NULL AS SubBetType,
				NULL AS SubHdp1,
				NULL AS SubHdp2,
				NULL AS SubOdds		
		FROM bettrans b WITH (NOLOCK)
			 INNER JOIN #t_exchanges te WITH (NOLOCK)
					 ON b.currency = te.exchangeid -- filter for @CurrencyCodes			 
			 INNER JOIN CUSTDB.dbo.Customer c WITH (NOLOCK)
					 ON b.recommend = c.custid
			 INNER JOIN #t_LicenseeNames tl WITH (NOLOCK)
					 ON tl.LicenseeName = c.site -- filter for @LicenseeIDs	
			 INNER JOIN match m WITH (NOLOCK)
					 ON b.matchid = m.matchid							 		 
		WHERE m.sporttype BETWEEN 1 AND 99 -- sportbook only			
			AND b.bettype NOT IN (9, 29) -- single
			AND b.bettype < 19001
			AND b.bettype NOT IN (31,32,33,71,72,73)	-- NOT IN [Racing, Casino]
			AND b.bettype NOT BETWEEN 801 AND 806-- MG
			AND b.bettype BETWEEN 901 AND 910 -- BT subticket
			AND b.bettype NOT BETWEEN 1501 AND 1599	-- NOT IN Keno
			AND NOT (b.Username like '%bettrade%' AND b.betdaqid = 0) -- current owner is not member bettrade			
			AND b.statusID NOT IN (101, 102) -- reject, void
			AND b.betfrom <> 'P' -- exclude phone betting
			AND b.matchid = @MatchID -- filer for @MatchID						
		
	--> parlay
	IF @SearchParlay = 1	
		INSERT INTO #SpecialDeleteBets(
					Stake,
					AwayId,
					BetCheck,
					BetId,
					BetTeam,
					BetType,
					CurrencyCode,
					Creator,
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
					GroupName,
					
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
				c.site AS GroupName,
				
				sub.transid AS SubTransId,
				sub.betcheck AS SubBetCheck,
				sub.betteam AS SubBetTeam,
				sub.bettype AS SubBetType,
				sub.hdp1 AS SubHdp1,
				sub.hdp2 AS SubHdp2,
				sub.odds AS SubOdds		
		FROM bettrans main WITH (NOLOCK)
			 INNER JOIN #t_exchanges te WITH (NOLOCK)
					 ON main.currency = te.exchangeid  -- filter for @CurrencyCodes
			 INNER JOIN CUSTDB.dbo.Customer c WITH (NOLOCK)
					 ON main.recommend = c.custid
			 INNER JOIN #t_LicenseeNames tl1 WITH (NOLOCK)
					 ON tl1.LicenseeName = c.site -- filter for @LicenseeIDs			 				 					 
			 
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
			AND sub.bettype BETWEEN 901 AND 910 -- BT subticket
			AND sub.bettype NOT BETWEEN 1501 AND 1599	-- NOT IN Keno
			AND sub.matchid = @matchid
			AND sub.statusID NOT IN (101, 102) -- reject, void
			AND sub.betfrom <> 'P' -- exclude phone betting			
		
	SELECT  Stake,
			AwayId,
			BetCheck,
			BetId,
			BetTeam,
			BetType,
			CurrencyCode,
			Creator,
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
			GroupName,
			
			SubTransId,
			SubBetCheck,
			SubBetTeam,
			SubBetType,
			SubHdp1,
			SubHdp2,
			SubOdds
	FROM	#SpecialDeleteBets s		
		
	DROP TABLE #SpecialDeleteBets	
	DROP TABLE #t_LicenseeNames
	DROP TABLE #t_exchanges
			
	SET NOCOUNT OFF
END
GO

GRANT EXECUTE ON [dbo].[NAP_SpecialDelete_VoidByCurrency_Select]  TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialDelete_VoidByCurrency_Select]  TO [vnteam] AS [dbo]
GO
			