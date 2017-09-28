/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[U3_Rpt_WinLossByBettype_SAg]
	@CustID INT,
	@FromDate SMALLDATETIME,
	@ToDate SMALLDATETIME,	
	@BalanceUpDay SMALLDATETIME
AS

/*
	Created: 20150303@Sophia
	Task: U3 Report WinLoss By bettype - for Number game, Bingo, Live Casino
	DB: DBAGE/bodb02
	Original: Age_Rpt_WinLossByBettype_SAg

	Revisions:
		- 20170830@Percy: Integrate Lucky 3 [RedmineID: #76770]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SAgWinLoss TABLE
	(
		bettype int, 
		liveindicator  int, 
		GrossComm money,
		TurnOver money, 
		MAgTotal money, 
		SAgWinlost money, 
		Comm money, 
		SAgTotal money, 
		Company money,
		NoOfTicket int
	)

	----Get Sport Bettype Matrix------
	DECLARE @ProductIds VARCHAR(MAX), @isTest BIT
	SELECT  @ProductIds = dbo.U3_f_GetProductList(), @isTest = dbo.f_CheckSPVersion(@@PROCID)

	DECLARE @SportBettype TABLE (ProductID INT, Bettype INT)
	INSERT INTO @SportBettype (ProductID, Bettype)
	SELECT ProductID, Bettype FROM dbo.f_SportBettypeMatrixByProduct_Sel (@ProductIds, @isTest)

	IF @Todate >= @BalanceUpDay 
	BEGIN	
		INSERT INTO @SAgWinLoss
		SELECT b.bettype
			,liveindicator
			,SUM(isnull(scomm / (1 - tpositiontaking), 0)) AS GrossComm
			,SUM(ABS(stake)) AS TurnOver
			,SUM(mwinlost + awinlost + acomm + winlost - actual_stake)
			,SUM(swinlost)
			,isnull(SUM(scomm), 0) - isnull(SUM(acomm), 0)
			,isnull(SUM(swinlost), 0) + isnull(SUM(scomm), 0) - SUM(acomm)
			,- (isnull(SUM(swinlost), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(scomm), 0) + isnull(SUM(winlost - actual_stake), 0))
			,COUNT(transid) AS NoOfTicket
		FROM dbo.bettrans b WITH (NOLOCK, INDEX = IX_srecommend)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		WHERE 1 = 1
			AND winlostdate BETWEEN @FromDate AND @ToDate			
			AND statusID NOT IN (101, 102, 103) --- ('VOID', 'REJECT', 'Refund')
			AND ruben = 1  
			AND SRecommend = @CustID
			AND s.ProductID IN (3) --- Number Game
		GROUP BY b.bettype, b.liveindicator

		UNION ALL --- Not number Game not group by liveindicator
		SELECT 
			b.bettype
			,0 AS liveindicator
			,SUM(isnull(scomm / (1 - tpositiontaking), 0)) AS GrossComm
			,SUM(ABS(stake)) AS TurnOver
			,SUM(mwinlost + awinlost + acomm + winlost - actual_stake)
			,SUM(swinlost)
			,isnull(SUM(scomm), 0) - isnull(SUM(acomm), 0)
			,isnull(SUM(swinlost), 0) + isnull(SUM(scomm), 0) - SUM(acomm)
			,- (isnull(SUM(swinlost), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(scomm), 0) + isnull(SUM(winlost - actual_stake), 0))
			,COUNT(transid) AS NoOfTicket
		FROM dbo.bettrans b WITH (NOLOCK, INDEX = IX_srecommend)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		WHERE 1 = 1
			AND winlostdate BETWEEN @FromDate AND @ToDate				
			AND statusID NOT IN (101, 102, 103) --- ('VOID', 'REJECT', 'Refund')
			AND ruben = 1  
			AND SRecommend = @CustID
			AND s.ProductID <> 3 -- Not Number Game
		GROUP BY b.bettype 

		INSERT INTO @SAgWinLoss
		SELECT b.bettype
			,liveindicator
			,SUM(isnull(scomm / (1 - tpositiontaking), 0)) AS GrossComm
			,SUM(ABS(stake)) AS TurnOver
			,SUM(mwinlost + awinlost + acomm + winlost - actual_stake)
			,SUM(swinlost)
			,isnull(SUM(scomm), 0) - isnull(SUM(acomm), 0)
			,isnull(SUM(swinlost), 0) + isnull(SUM(scomm), 0) - SUM(acomm)
			,- (isnull(SUM(swinlost), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(scomm), 0) + isnull(SUM(winlost - actual_stake), 0))
			,COUNT(transid) AS NoOfTicket
		FROM dbo.bettrans14 b WITH (NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		WHERE 1 = 1
			AND winlostdate BETWEEN @FromDate AND @ToDate
			AND statusID NOT IN (101, 102, 103)
			AND ruben = 1
			AND Srecommend = @CustID
			AND s.ProductID IN (3) --- Number Game
		GROUP BY b.bettype, b.liveindicator

		UNION ALL --- Not number Game not group by liveindicator
		SELECT 
			b.bettype
			,0 AS liveindicator
			,SUM(isnull(scomm / (1 - tpositiontaking), 0)) AS GrossComm
			,SUM(ABS(stake)) AS TurnOver
			,SUM(mwinlost + awinlost + acomm + winlost - actual_stake)
			,SUM(swinlost)
			,isnull(SUM(scomm), 0) - isnull(SUM(acomm), 0)
			,isnull(SUM(swinlost), 0) + isnull(SUM(scomm), 0) - SUM(acomm)
			,- (isnull(SUM(swinlost), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(scomm), 0) + isnull(SUM(winlost - actual_stake), 0))
			,COUNT(transid) AS NoOfTicket
		FROM dbo.bettrans14 b WITH (NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype		
		WHERE 1 = 1
			AND winlostdate BETWEEN @FromDate AND @ToDate				 
			AND statusID NOT IN (101, 102, 103)
			AND ruben = 1
			AND Srecommend = @CustID
			AND s.ProductID <> 3 -- Not Number Game
		GROUP BY b.bettype
	END

	SELECT bettype,
		   liveindicator,
		   SUM(GrossComm) as GrossComm,
		   SUM(TurnOver) as TurnOver,	
		   SUM(MAgTotal) as MAgTotal,
		   SUM(SAgWinlost) as SAgWinlost,
		   SUM(Comm) as Comm,
		   SUM(SAgTotal) as SAgTotal,
		   SUM(Company) as Company,
		   SUM(NoOfTicket) as NoOfTicket
	FROM @SAgWinLoss 
	GROUP BY bettype, liveindicator
	ORDER BY bettype, liveindicator
END
GO