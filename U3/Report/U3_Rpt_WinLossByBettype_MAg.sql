ALTER PROCEDURE [dbo].[U3_Rpt_WinLossByBettype_MAg]
	@CustID INT,
	@FromDate SMALLDATETIME,
	@ToDate SMALLDATETIME,	
	@BalanceUpDay SMALLDATETIME
AS
/*
Created: 20150303@Sophia
Task : U3 Report WinLoss By bettype - for Number game, Bingo, Live Casino 
DB: DBAGE/bodb02
Original: Age_Rpt_WinLossByBettype_MAg
Revisions:
    

*/
SET NOCOUNT ON
DECLARE @MAgWinLoss TABLE
(
	bettype int, 
	liveindicator int,
	GrossComm money,
	TurnOver money, 
	AgTotal money, 
	MAgWinlost money, 
	Comm money, 
	MAgTotal money, 
	Company money,
	NoOfTicket int
) 


----Get Sport Bettype Matrix------
DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
INSERT INTO @SportBettype
EXEC dbo.Acc_SportBettypeMatrix_Sel @mode=4


IF @Todate >= @BalanceUpDay 
BEGIN
		INSERT INTO @MAgWinLoss
		SELECT b.bettype
			,liveindicator
			,SUM(acomm / (1 - apositiontaking - mpositiontaking)) AS GrossComm
			,SUM(ABS(stake)) AS TurnOver
			,isnull(SUM(winlost - actual_stake), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(comm), 0)
			,SUM(mwinlost)
			,isnull(SUM(acomm), 0) - isnull(SUM(comm), 0)
			,isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0) - SUM(comm)
			,- (isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0) + isnull(SUM(winlost - actual_stake), 0))
			,COUNT(transid) AS NoOfTicket
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		WHERE 1 = 1
			AND winlostdate BETWEEN @FromDate AND @ToDate
			AND statusID NOT IN (101, 102, 103) --- ('VOID', 'REJECT', 'Refund')
			AND ruben = 1
			AND mrecommend = @CustID
			AND s.ProductID IN (3) --- Number Game
		GROUP BY b.bettype, b.liveindicator

		UNION ALL --- Not number Game not group by liveindicator
		SELECT
			b.bettype
			,0 AS liveindicator
			,SUM(acomm / (1 - apositiontaking - mpositiontaking)) AS GrossComm
			,SUM(ABS(stake)) AS TurnOver
			,isnull(SUM(winlost - actual_stake), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(comm), 0)
			,SUM(mwinlost)
			,isnull(SUM(acomm), 0) - isnull(SUM(comm), 0)
			,isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0) - SUM(comm)
			,- (isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0) + isnull(SUM(winlost - actual_stake), 0))
			,COUNT(transid) AS NoOfTicket
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype		
		WHERE 1 = 1
			AND winlostdate BETWEEN @FromDate AND @ToDate
			AND statusID NOT IN (101, 102, 103) ---('VOID', 'REJECT', 'Refund')
			AND ruben = 1
			AND mrecommend = @CustID
			AND s.ProductID IN (4, 7)  --- Bingo, Live Casino
		GROUP BY b.bettype

		
		INSERT INTO @MAgWinLoss
		SELECT b.bettype
			,liveindicator
			,SUM(acomm / (1 - apositiontaking - mpositiontaking)) AS GrossComm
			,SUM(ABS(stake)) AS TurnOver
			,isnull(SUM(winlost - actual_stake), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(comm), 0)
			,SUM(mwinlost)
			,isnull(SUM(acomm), 0) - isnull(SUM(comm), 0)
			,isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0) - SUM(comm)
			,- (isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0) + isnull(SUM(winlost - actual_stake), 0))
			,COUNT(transid) AS NoOfTicket
		FROM dbo.bettrans14 b WITH (NOLOCK, INDEX = IX_bettrans4)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype	
		WHERE 1 = 1
			AND winlostdate BETWEEN @FromDate AND @ToDate					
			AND statusID NOT IN (101, 102, 103)  -----('VOID', 'REJECT', 'Refund') 
			AND ruben = 1
			AND mrecommend = @CustID
			AND s.ProductID IN (3) --- Number Game
		GROUP BY b.bettype, b.liveindicator

		UNION ALL
		SELECT 
			 b.bettype
			,0 AS liveindicator
			,SUM(acomm / (1 - apositiontaking - mpositiontaking)) AS GrossComm
			,SUM(ABS(stake)) AS TurnOver
			,isnull(SUM(winlost - actual_stake), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(comm), 0)
			,SUM(mwinlost)
			,isnull(SUM(acomm), 0) - isnull(SUM(comm), 0)
			,isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0) - SUM(comm)
			,- (isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0) + isnull(SUM(winlost - actual_stake), 0))
			,COUNT(transid) AS NoOfTicket
		FROM dbo.bettrans14 b WITH (NOLOCK, INDEX = IX_bettrans4)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype	
		WHERE 1 = 1
			AND winlostdate BETWEEN @FromDate AND @ToDate					
			AND statusID NOT IN (101, 102, 103) ----('VOID', 'REJECT', 'Refund')
			AND ruben = 1
			AND mrecommend = @CustID
			AND s.ProductID IN (4, 7)  --- Bingo, Live Casino
		GROUP BY B.bettype
 
END

SELECT bettype, liveindicator,
       SUM(GrossComm) as GrossComm,
	   SUM(TurnOver) as TurnOver,	
	   SUM(AgTotal) as AgTotal,
	   SUM(MAgWinlost) as MAgWinlost,
	   SUM(Comm) as Comm,
	   SUM(MAgTotal) as MAgTotal,
	   SUM(Company) as Company,
       SUM(NoOfTicket) as NoOfTicket
  FROM @MAgWinLoss 
 Group by bettype, liveindicator
 ORDER BY bettype, liveindicator

GO
GRANT EXECUTE ON [dbo].[U3_Rpt_WinLossByBettype_MAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[U3_Rpt_WinLossByBettype_MAg] TO [bodbDownlineNetView]
GO