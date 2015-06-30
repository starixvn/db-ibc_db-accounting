CREATE PROCEDURE [dbo].[Acc_Rpt_WinlostMG_Details14]
	@WinlostDate	DATETIME,
	@SubProduct		VARCHAR(500) = 'MG-SuperLive'
AS 
/*	
	Creator:20150520@Sophia
	Task: Report 2a for Metrix Gaming 
	DB:  DBACC/bodb02
	Original: 
	
	Revisions :
			 
	Explanation's Param:

*/
	SET NOCOUNT ON

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5

	SELECT b.bettype
		,ISNULL(SUM ((1 - tpositiontaking) * ABS(stake) * actualrate), 0) Turnover
		,ISNULL(SUM ((winlost - actual_stake) * b.actualrate), 0) winlost
		,ISNULL(SUM ((awinlost + mwinlost + swinlost) * b.actualrate), 0) pos
		,ISNULL(SUM (scomm * b.actualrate), 0) comm
		,ISNULL(SUM ((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * b.actualrate), 0) AS LineTotal
	FROM dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN @SportBettype s
				ON b.Bettype = s.Bettype
	WHERE s.ProductID = 1
		AND s.SubProduct = @SubProduct
		AND b.Winlostdate = @WinlostDate
		AND b.ruben = 1
		AND b.statusID NOT IN (101, 102, 121)
	GROUP BY b.bettype
	ORDER BY b.bettype

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostMG_Details14] TO [bodbAdminNet]
GO

