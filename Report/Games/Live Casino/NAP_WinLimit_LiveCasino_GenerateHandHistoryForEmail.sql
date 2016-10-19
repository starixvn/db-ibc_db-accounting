USE [bodb02]
GO

/*
	Created:	Harper@20161013
	Task:		#61220: Generate data for HandHistory tab of Email Template Phase 3
	DB:			DBEXT.bodb02

	Revisions:

	Param's Explanation:
		@UserID: User that reach Win Limit
		@ReachedDate: date that user reach win limit

	EXEC NAP_WinLimit_GenerateHandHistoryForEmail @UserID = 18205717, @ReachedDate = '20161010' WITH RECOMPILE
*/

ALTER PROC NAP_WinLimit_GenerateHandHistoryForEmail
	@UserID INT,
	@ReachedDate DATETIME
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ShortReachedDate DATE = CONVERT(VARCHAR(10), @ReachedDate, 111)	

	DECLARE @TmpCasino TABLE
	(
		TranstionID		INT,
		StatusID		INT,
		WinLoss			MONEY,
		GameCode		NVARCHAR(50),
		Brand			VARCHAR(5),
		Game			VARCHAR(50),
		GameType		NVARCHAR(50),
		GameGroup		NVARCHAR(1000),
		BetType			NVARCHAR(50),
		BetDate			DATETIME,
		GameDate		DATETIME,
		TimeDiff		TIME,
		GameDuration	TIME,
		TotalBet		MONEY,
		PlayerWL		MONEY,
		GameIncome		MONEY,
		CompanyTurnOver MONEY,
		CompanyComm		MONEY,
		CompanyNetIncome MONEY,
		Result			NVARCHAR(100),
		H				MONEY,
		S				MONEY,
		M				MONEY,
		A				MONEY
	)

	INSERT INTO @TmpCasino	        
	SELECT
		bg.transid
		, bg.statusID 	
		, bg.winlost	
		, m.matchcode		AS GameCode
		, 'SLI'				AS Brand
		, 'Live Casino'		AS Game
		, b.typenamee		AS GameType
		, l.leaguename		AS GameGroup
		, bg.betteam		AS BetType
		, bg.transdate		AS BetDate
		, m.eventdate		AS GameDate -- Need To Confirm
		, ''				AS TimeDiff 
		, CONVERT(TIME, (m.kickofftime - m.settletime)) AS GameDuration
		, bg.stake			AS TotalBet
		, (bg.winlost - bg.stake)	AS PlayerWL
		, 0							AS GameInCome 
		, (1 - bg.tpositiontaking) * bg.stake			AS CompanyTurnOver
		, bg.scomm					AS CompanyComm
		, 0							AS CompanyNetIncome 
		, m.betstatus				AS Result
		, (1 - bg.tpositiontaking)	AS H
		, bg.spositiontaking		AS S
		, bg.mpositiontaking		AS M
		, bg.apositiontaking		AS A
	FROM dbo.bettransG bg (NOLOCK)
		INNER JOIN dbo.match m (NOLOCK) ON bg.matchid = m.matchid
		INNER JOIN dbo.bettype b (NOLOCK) ON bg.bettype = b.typeid
		INNER JOIN dbo.League l (NOLOCK) ON m.leagueid = l.leagueid
	WHERE m.sporttype = 162 AND bg.bettype IN (1101, 1102, 1103, 1104) -- For Live Casino
		AND bg.statusID NOT IN (0, 1, 101, 102, 103) -- running, void, reject, refund
		AND bg.custid = @UserID AND CONVERT(VARCHAR(10), bg.transdate, 111) = @ShortReachedDate 

	-- Update Time Difference
	UPDATE T
	SET T.TimeDiff = CONVERT(TIME, R.TimeDiff)
	FROM
	(
		SELECT B.TranstionID, (B.GameDate - A.GameDate) AS TimeDiff
		FROM @TmpCasino A CROSS JOIN @TmpCasino B
		WHERE B.TranstionID IN (SELECT MIN (C.TranstionID) FROM @TmpCasino C WHERE C.TranstionID > A.TranstionID)		
	) AS R INNER JOIN @TmpCasino T ON R.TranstionID = T.TranstionID	
	
	-- Update Game Income, Company Net Income
	UPDATE @TmpCasino
	SET GameIncome = TotalBet - WinLoss
	
	UPDATE @TmpCasino
	SET CompanyNetIncome = (GameIncome * H) - CompanyComm

	SELECT GameCode,
		Brand,
		Game,
		GameType,
		GameGroup,
		BetType,
		BetDate,
		GameDate,
		TimeDiff,
		GameDuration,
		TotalBet,
		PlayerWL,
		GameIncome,
		CompanyTurnOver,
		CompanyComm,
		CompanyNetIncome,
		Result,
		H,
		S,
		M,
		A	
	FROM @TmpCasino

	SELECT t.GameCode, COUNT(t.TranstionID) AS NoTicket, SUM(t.TotalBet) AS TotalBet, SUM(t.GameIncome) AS GameInCome
	FROM @TmpCasino t
	GROUP BY t.GameCode

END
GO