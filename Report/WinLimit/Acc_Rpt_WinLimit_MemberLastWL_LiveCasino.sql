USE [bodb02]
GO

CREATE PROCEDURE Acc_Rpt_WinLimit_MemberLastWL_LiveCasino
	@CustID INT,
	@ReachedDate DATETIME
AS
/*
	Created:	Harper@20161025
	Task:		#61220: Generate data for Section 3 - Member Last Win/Loss
	DB:			DBEXT.bodb02

	Revisions:

	Param's Explanation:
		@CustID: Customer that reach Win Limit
		@ReachedDate: date that user reach win limit

	EXEC Acc_Rpt_WinLimit_HandHistory_LiveCasino @CustID = 18205717, @ReachedDate = '20161010' WITH RECOMPILE
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @ShortReachedDate DATE = CONVERT(VARCHAR(10), @ReachedDate, 111)	
	
	SELECT b.custid
		, b.winlostdate
		, b.bettype
		, b.currency
		, b.CurrencyName
		, b.transid AS BetCount
		, b.actual_stake AS TotalBet
		, b.actual_stake - b.winlost AS GameIncome
		, CASE WHEN b.actual_stake <= 0 THEN 0 ELSE b.winlost/b.actual_stake END AS GamePayout
		, (1 - b.tpositiontaking) * b.stake AS CompanyTurnOver
		, (b.winlost - b.actual_stake + b.awinlost + b.mwinlost + b.swinlost + b.scomm) AS CompanyNetIncome		
		, b.actual_stake * b.actualrate AS BasedTotalBet
		, (b.actual_stake - b.winlost) * b.actualrate AS BasedGameIncome
		, ((1 - b.tpositiontaking) * b.stake) * b.actualrate AS BasedCompanyTurnOver
		, (b.winlost - b.actual_stake + b.awinlost + b.mwinlost + b.swinlost + b.scomm) * b.actualrate AS BasedCompanyNetIncome
	FROM dbo.bettrans b (NOLOCK)
	WHERE b.statusID NOT IN (0, 1, 101, 102, 103) -- running, void, reject, refund		
		AND b.custid = @CustID AND CONVERT(VARCHAR(10), b.winlostdate, 111) = @ShortReachedDate 
	
END
GO
