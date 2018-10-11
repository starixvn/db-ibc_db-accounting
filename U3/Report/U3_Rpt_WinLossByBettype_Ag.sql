/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[U3_Rpt_WinLossByBettype_Ag]
	@CustID 	INT,
	@FromDate 	SMALLDATETIME,
	@ToDate 	SMALLDATETIME,	
	@BalanceUpDay SMALLDATETIME	
AS

/*
	Created: 20150303@Sophia
	Task: U3 Report WinLoss By bettype - for Number game, Bingo, Live Casino
	DB: DBAGE/bodb02
	Original: Age_Rpt_WinLossByBettype_Ag

	Revisions:
		- 20170830@Percy: Integrate Lucky 3 [RedmineID: #76770]
		- 20181003@Helen: Modify code to adapt indexes changed on DB053 [Redmine:101405]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AgWinLoss TABLE
	(
		bettype int, 
		liveindicator int,
		GrossComm money,
		TurnOver money, 
		MemberWinLost money, 
		AgWinLost money, 
		PlayerComm money, 
		AgComm money, 
		MemberTotal money, 
		AgTotal money, 
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
		INSERT INTO @AgWinLoss
		SELECT b.bettype,
			   b.liveindicator,
			   SUM(comm/(1 - apositiontaking)) as GrossComm,
			   SUM(ABS(stake)) as TurnOver,
			   SUM(winlost - actual_stake),
			   SUM(awinlost),
			   SUM(playercomm),
			   SUM(comm - playercomm),
			   isnull(SUM(winlost - actual_stake), 0) + isnull(SUM(playercomm), 0) as MemberTotal,
			   isnull(SUM(awinlost), 0) + isnull(SUM(comm - playercomm), 0) as AgTotal,
		       -SUM(winlost - actual_stake + awinlost + comm),
			   COUNT(transid) as NoOfTicket
         FROM  dbo.Bettrans b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		 WHERE	1 = 1
			AND b.winlostdate BETWEEN @FromDate AND @ToDate
			AND b.ruben = 1
			AND b.statusID NOT IN (101, 102, 103)  ------('VOID', 'REJECT', 'Refund')
			AND b.recommend = @custid
			AND s.ProductID IN (3) --- Number Game
		GROUP BY b.bettype, b.liveindicator
		
	    UNION ALL --- Not number Game not group by liveindicator
		SELECT 
			   b.bettype,
			   0 as liveindicator,
		       SUM(comm/(1 - apositiontaking)) as GrossComm,
		       SUM(ABS(stake)) as TurnOver,
			   SUM(winlost - actual_stake),
			   SUM(awinlost),
			   SUM(playercomm),
			   SUM(comm-playercomm),
			   isnull(SUM(winlost - actual_stake), 0) + isnull(SUM(playercomm), 0) as MemberTotal,
			   isnull(SUM(awinlost), 0) + isnull(SUM(comm - playercomm), 0) as AgTotal,
			   -SUM(winlost - actual_stake + awinlost + comm),
			   COUNT(transid) as NoOfTicket
		FROM Bettrans b WITH(NOLOCK)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype		
		WHERE 1 = 1		  
			AND winlostdate BETWEEN @FromDate AND @ToDate
			AND ruben = 1
			AND statusID NOT IN (101, 102, 103) ------('VOID', 'REJECT', 'Refund')
			AND recommend = @custid
			AND s.ProductID <> 3 -- Not Number Game
		GROUP BY b.bettype


		INSERT INTO @AgWinLoss
		SELECT b.bettype,
		       liveindicator,
		       SUM(comm/(1 - apositiontaking)) as GrossComm,
		       SUM(ABS(stake)) as TurnOver,
			   SUM(winlost - actual_stake),
			   SUM(awinlost),
			   SUM(playercomm),
			   SUM(comm - playercomm),
			   isnull(SUM(winlost - actual_stake), 0) + isnull(SUM(playercomm), 0) as MemberTotal,
			   isnull(SUM(awinlost), 0) + isnull(SUM(comm - playercomm), 0) as AgTotal,
			   -SUM(winlost - actual_stake + awinlost + comm),
			   COUNT(transid) as NoOfTicket
		FROM Bettrans14 b WITH(NOLOCK, INDEX = IX_recommend)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype		
		WHERE 1 = 1		 
			AND winlostdate BETWEEN @FromDate AND @ToDate
			AND ruben = 1
			AND statusID NOT IN (101, 102, 103) ------('VOID', 'REJECT', 'Refund')
			AND recommend = @custid
			AND s.ProductID IN (3) --- Number Game
		GROUP BY b.bettype, liveindicator

        UNION ALL
		SELECT 
			   b.bettype,
		       0 as liveindicator,
		       SUM( comm/(1 - apositiontaking)) as GrossComm,
		       SUM(ABS(stake)) as TurnOver,
			   SUM(winlost - actual_stake),
			   SUM(awinlost),
			   SUM(playercomm),
			   SUM(comm - playercomm),
			   isnull(SUM(winlost-actual_stake), 0) + isnull(SUM(playercomm), 0) as MemberTotal,
			   isnull(SUM(awinlost), 0) + isnull(SUM(comm-playercomm), 0) as AgTotal,
			   -SUM(winlost - actual_stake + awinlost+comm),
			   COUNT(transid) as NoOfTicket
		FROM Bettrans14 b WITH(NOLOCK, INDEX = IX_recommend)
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype	
		WHERE 1 = 1
		    AND winlostdate BETWEEN @FromDate AND @ToDate
			AND ruben = 1
			AND statusID NOT IN (101, 102, 103) ------('VOID', 'REJECT', 'Refund')
			AND recommend = @custid
			AND s.ProductID <> 3 -- Not Number Game
		GROUP BY b.bettype
	END

	SELECT bettype,
		   liveindicator,
		   SUM(GrossComm) as GrossComm,
		   SUM(TurnOver) as TurnOver,
		   SUM(MemberWinLost) as MemberWinLost,
		   SUM(playercomm) as PlayerComm,
		   SUM(MemberTotal) as MemberTotal,
		   SUM(AgWinLost) as AgWinLost,
		   SUM(AgComm) as AgComm,
		   SUM(AgTotal) as AgTotal,
		   SUM(company) as Company,
		   SUM(NoOfTicket) as NoOfTicket
	FROM @AgWinLoss
	GROUP BY bettype, liveindicator
	ORDER BY bettype, liveindicator
END
GO